package WWW::Contact::Indiatimes;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.16';
our $AUTHORITY = 'cpan:SACHINJSK';

sub get_contacts {
    my ($self, $email, $password) = @_;

    # reset errstr
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from Indiatimes");
    
    # Get username from email.
    $email =~ /(.*)@.*/;
    my $username = $1;
    
    # get to login form
    $self->get('http://in.indiatimes.com/') || return;

    $self->submit_form(
        form_name   => 'loginfrm',
        form_number => 3,
        fields    => {
            login  => $username,
            passwd => $password,
        },
    ) || return;
    
    my $content = $ua->content();
    if ($content =~ /Invalid User/ig) {
        $self->errstr('Wrong Username or Password');
        return;
    }

    $self->debug('Login OK');
    
    $self->get("/home/$username/Contacts.csv");

    my $address_content = $ua->content();
    @contacts = get_contacts_from_csv($address_content);
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_csv {
    my ($csv) = shift;
    my @contacts;
 
    # e-mail, file_as, first_name, last_name
    my @lines = split(/\n/, $csv);
    shift @lines; # skip the first line
    foreach my $line (@lines) {
        $line =~ s/"//g;
        my @cols = split(',', $line);
        push @contacts, {
            name  => $cols[2].' '.$cols[3],
            email => $cols[0]
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::Indiatimes - Get contacts from Indiatimes

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@indiatimes.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get contacts from Indiatimes. Extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Contact::Base>, L<WWW::Mechanize>

=head1 AUTHOR

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Sachin Sebastian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
