package WWW::Contact::Rediffmail;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:SACHINJSK';

has '+ua_class' => ( default => 'WWW::Mechanize::GZip' );

sub get_contacts {
    my ($self, $email, $password) = @_;

    # reset errstr
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from Rediff");
    
    # Get username from email.
    $email =~ /(.*)@.*/;
    my $username = $1;
    
    # get to login form
    $self->get('http://www.rediff.com') || return;

    $self->submit_form(
        form_name => 'loginform',
        fields    => {
            login  => $username,
            passwd => $password,
        },
    ) || return;
    
    my $content = $ua->content();
    if ($content =~ /Your login failed/ig) {
        $self->errstr('Wrong Username or Password');
        return;
    }

    $self->debug('Login OK');
    
    $ua->follow_link( url_regex => qr/login=/i );
    my $link = $ua->follow_link( url_regex => qr/folder=inbox/i );
    $content = $ua->content;

    # Go to new Rediffmail, if taken to old one.
    if ($content =~ /new Rediffmail/ig) {
        $link = $ua->follow_link(text_regex => qr/new Rediffmail/i );
    }
    
    # get url and session id.
    my $base_link = $link->base();
    $base_link =~ /(.*)\?.*session_id=(.*?)&/;
    my $base_url   = $1;
    my $session_id = $2;

    $self->get("$base_url?do=downaddrbook&login=$username&session_id=$session_id&service=thunderbird");

    my $address_content = $ua->content();
    @contacts = get_contacts_from_thunderbird_csv($address_content);
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_thunderbird_csv {
    my ($csv) = shift;
    my @contacts;
 
    # first_name, last_name, full_name, nickname, e-mail.
    my @lines = split(/\n/, $csv);
    shift @lines; # skip the first line
    foreach my $line (@lines) {
        my @cols = split(',', $line);
        push @contacts, {
            name  => $cols[2],
            email => $cols[4]
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;

1;
__END__

=head1 NAME

WWW::Contact::Rediffmail - Get contacts from Rediffmail

=head1 SYNOPSIS

    use WWW::Contact::Rediffmail;
    
    my $wc       = WWW::Contact::Rediffmail->new();
    my @contacts = $wc->get_contacts('email@rediffmail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get contacts from Rediff Mail. extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Contact::Base>, L<WWW::Mechanize::GZip>

=head1 AUTHOR

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Sachin Sebastian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
