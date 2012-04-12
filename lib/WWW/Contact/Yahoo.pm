package WWW::Contact::Yahoo;

use Encode qw( decode );
use Moose;
extends 'WWW::Contact::Base';
use Encode;

our $VERSION   = '0.46';
our $AUTHORITY = 'cpan:FAYLAND';

has '+ua_class' => ( default => 'WWW::Mechanize::GZip' );

use HTML::TreeBuilder;

sub get_contacts {
    my ($self, $email, $password) = @_;

    # reset
    $self->errstr(undef);
    my @contacts;

    my $ua = $self->ua;
    $self->debug("start get_contacts from Yahoo!");

    # to form
    $self->get('https://login.yahoo.com/config/login_verify2?&.src=ym') || return;
    $self->submit_form(
        form_name => 'login_form',
        fields    => {
            login  => $email,
            passwd => $password,
        },
    ) || return;
    my $content = $ua->content();
    if ($content =~ /=[\'\"]yregertxt/) {
        $self->errstr('Wrong Username or Password');
        return;
    }

    # https://edit.yahoo.com/recovery/update
    if ( $ua->base =~ /recovery\/update/ ) {
        $self->errstr("Account Recovery Issue");
        return;
    }

    $self->debug('Login OK');

    $self->get('http://address.mail.yahoo.com/?_src=&VPC=tools_print') || return;

    $self->submit_form(
        with_fields => {
            'field[allc]' => 1,
            'field[style]' => 'quick',
        },
        button => 'submit[action_display]',
    ) || return;

    my $tree = HTML::TreeBuilder->new_from_content( decode('utf8', $ua->content) );
    my @tables = $tree->look_down( '_tag', 'table', 'class', 'qprintable2' );
    while (my $table = shift @tables) {
        # two tr, one has class phead
        my @trs = $table->look_down( '_tag', 'tr' );
        my ($phead_tr, @other_tr);
        while (my $tr = shift @trs) {
            if ( $tr->attr('class') and $tr->attr('class') eq 'phead' ) {
                $phead_tr = $tr;
            } else {
                push @other_tr, $tr;
            }
        }
        my $name = $phead_tr->look_down( '_tag', 'b' )->as_text;
        $name ||=  $phead_tr->look_down( '_tag', 'i' ) ? $phead_tr->look_down( '_tag', 'i' )->as_text : '';
        my $yahoo_id = $phead_tr->look_down( '_tag', 'small' ) ? $phead_tr->look_down( '_tag', 'small' )->as_text : '';
        my $email;
        OTR: while (my $tr = shift @other_tr) {
            my @divs = $tr->look_down( '_tag', 'div' );
            foreach my $div (@divs) {
                my $text = $div->as_text;
                next unless $text;
                if ( $text =~ /\@/ ) {
                    $email = $text;
                    last OTR;
                }
            }
        }
        if (not $email and $yahoo_id) {
            # treat as '@yahoo.com' by default
            $email = ($yahoo_id =~ /\@/) ? $yahoo_id : $yahoo_id . '@yahoo.com';
        }
        next unless $email;
        $name =~ s/(^\s+|\s+$)//g;
        $name ||= $yahoo_id;
        push @contacts, {
            name => $name,
            email => $email,
        };
    }
    $tree = $tree->delete;

    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::Yahoo - Get contacts/addressbook from Yahoo! Mail

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;

    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@yahoo.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get addressbook from Yahoo! Mail. Extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize::GZip>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
