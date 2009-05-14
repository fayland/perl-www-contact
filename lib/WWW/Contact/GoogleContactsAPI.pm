package WWW::Contact::GoogleContactsAPI;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.23';
our $AUTHORITY = 'cpan:FAYLAND';

has authsub => (
    is => 'ro',
    isa => 'Net::Google::AuthSub',
    lazy => 1,
    default => sub {
        require Net::Google::AuthSub;
        Net::Google::AuthSub->new(service => 'cp');
    },
);

has 'json' => (
    is => 'ro',
    isa => 'JSON::XS',
    lazy => 1,
    default => sub {
        require JSON::XS;
        return JSON::XS->new->utf8;
    }
);

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    my @contacts;
    
    my $resp = $self->authsub->login($email, $password);
    unless ( $resp and $resp->is_success ) {
        $self->errstr('Wrong Username or Password'); ### XXX? CaptchaRequired
        return;
    }
    
    $self->get( "http://www.google.com/m8/feeds/contacts/default/full?max-results=9999&alt=json", $self->authsub->auth_params );
    my $content = $self->ua->content();
    my $data = $self->json->decode($content);
    
    if ( $data and $data->{feed} and $data->{feed}->{entry} ) {
        foreach my $entry ( @{ $data->{feed}->{entry} } ) {
            my $email = $entry->{'gd$email'}->[0]->{address};
            next unless $email;
            my $name  = $entry->{title}->{'$t'} || $email;
            push @contacts, {
                name  => $name,
                email => $email,
            }
        }
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::GoogleContactsAPI - Get contacts/addressbook by Google Contacts Data API

=head1 SYNOPSIS

    use WWW::Contact;
    
    my $wc = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@gmail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

L<http://code.google.com/apis/contacts/docs/2.0/reference.html>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<Net::Google::AuthSub>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
