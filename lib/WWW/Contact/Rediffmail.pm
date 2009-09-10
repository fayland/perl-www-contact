package WWW::Contact::Rediffmail;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:SACHINJSK';

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
    $ua->follow_link( url_regex => qr/folder=inbox/i );
    $content = $ua->content;

    # Go to new Rediffmail, if taken to old one.
    if ($content =~ /new Rediffmail/i) {
        $ua->follow_link(text_regex => qr/new Rediffmail/i );
    }
    $self->get("/prism/exportaddrbook?output=web") || return;

    my $uri = $ua->uri->as_string;
    $self->ua->current_form->action("$uri&service=thunderbird");
    $self->submit_form(
        form_name => 'exportaddr',
        fields    => {
            exporttype => 'thunderbird',
        },
    ) || return;

    my $address_content = $ua->content();
    @contacts = get_contacts_from_thunderbird_csv($address_content);
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_thunderbird_csv {
    my ($csv) = shift;
    my @contacts;
 
    # dn:cn=tester cpan,mail=tester_cpan@rediffmail.com
    my @lines = split(/\n/, $csv);
    foreach my $line (@lines) {
        next if $line !~ /^dn\:cn/;
        my ($name, $email) = ( $line =~ /cn=(.*?)\,mail=(.*?)$/ );
        push @contacts, {
            name  => $name,
            email => $email
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::Rediffmail - Get contacts from Rediffmail

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@rediffmail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get contacts from Rediff Mail. Extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Contact::Base>, L<WWW::Mechanize>

=head1 AUTHOR

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Sachin Sebastian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
