package WWW::Contact::Lycos;

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
    $self->debug("start get_contacts from lycos");
    
    # Get username from email.
    $email =~ /(.*)@.*/;
    my $username = $1;
    
    # get to login form
    $self->get('http://www.lycos.com/') || return;

    $self->submit_form(
        form_number   => 2,
        fields        => {
                m_U  => $username,
                m_P  => $password,
            },
    ) || return;
    
    my $content = $ua->content();
    if ($content =~ /password you provided don't match/ig) {
        $self->errstr('Wrong Username or Password');
        return;
    }

    $self->debug('Login OK');
    
    $self->get("http://mail.lycos.com/lycos/addrbook/ExportAddr.lycos?ptype=act&fileType=OUTLOOK");

    my $address_content = $ua->content();

    @contacts = get_contacts_from_csv($address_content);
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_csv {
    my ($csv) = shift;
    my @contacts;
 
    # first_name, middle_name, last_name, nickname, e-mail.
    my @lines = split(/\n/, $csv);
    shift @lines; # skip the first line
    foreach my $line (@lines) {
        $line =~ s/"//g;
        my @cols = split(',', $line);
        push @contacts, {
            name  => $cols[0].' '.$cols[2],
            email => $cols[4]
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::Lycos - Get contacts from Lycos

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@lycos.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get contacts from Lycos. Extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Contact::Base>, L<WWW::Mechanize>

=head1 AUTHOR

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Sachin Sebastian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
