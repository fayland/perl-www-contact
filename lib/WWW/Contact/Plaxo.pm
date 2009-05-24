package WWW::Contact::Plaxo;

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
    $self->debug("start get_contacts from Plaxo");
    
    # get to login form
    $self->get('https://www.plaxo.com/signin') || return;

    $self->submit_form(
        form_name   => 'form',
        fields    => {
            'signin.email'    => $email,
            'signin.password' => $password,
        },
    ) || return;
    
    my $content = $ua->content();
    if ($content =~ /too many login failures/ig) {
        $self->errstr('Account has had too many login failures recently and has been temporarily locked');
        return;
    }
    elsif ($content =~ /Sign in to Plaxo/ig) {
        $self->errstr('Wrong Username or Password');
        return;
    }

    $self->debug('Login OK');
    
    $self->get("http://www.plaxo.com/export/plaxo_ab_outlook.csv");

    $self->submit_form(
        form_name => 'form'
    ) || return;

    my $address_content = $ua->content();
    @contacts = get_contacts_from_csv($address_content);
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_csv {
    my ($csv) = shift;
    my @contacts;
 
    # title, first_name, middle_name, last_name, suffix, e-mail.
    my @lines = split(/\n/, $csv);
    shift @lines; # skip the first line
    foreach my $line (@lines) {
        $line =~ s/"//g;
        my @cols = split(',', $line);
        push @contacts, {
            name  => $cols[1].' '.$cols[3],
            email => $cols[5]
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::Plaxo - Get contacts from Plaxo

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;
    
    my $wc       = WWW::Contact->new();
    # Note that the last argument for get_contacts is mandatory,
    # or else it will try to fetch contacts from email.com
    my @contacts = $wc->get_contacts('itsa@email.com', 'password', 'plaxo');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get contacts from Plaxo. Extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Contact::Base>, L<WWW::Mechanize>

=head1 AUTHOR

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Sachin Sebastian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
