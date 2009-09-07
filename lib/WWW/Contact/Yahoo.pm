package WWW::Contact::Yahoo;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.29';
our $AUTHORITY = 'cpan:FAYLAND';

has '+ua_class' => ( default => 'WWW::Mechanize::GZip' );

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
    
    $self->debug('Login OK');

    $self->get('http://address.mail.yahoo.com/?VPC=contact_list&.rand=' . time()) || return;
    $ua->follow_link( url_regex => qr/import_export/i );
    
    $ua->form_number(0); # the last form
    $self->submit_form(
        button      => 'submit[action_export_yahoo]',
    );
    
    $content = $ua->content();
    my $i;
    while ( $content
        =~ /^\"(.*?)\"\,\".*?\"\,\"(.*?)\"\,\".*?\"\,\"(.*?)\"\,\".*?\"\,\".*?\"\,\"(.*?)\"/mg
        ) {
        $i++;
        next if ( $i == 1 );    # skip the first line.
        next unless ( $3 or $4 );
        my $email = $3 || $4 . '@yahoo.com';
        my $name = ( $1 or $2 ) ? "$1 $2" : $4;
        push @contacts, {
            name       => $name,
            email      => $email,
        };;
    }

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
