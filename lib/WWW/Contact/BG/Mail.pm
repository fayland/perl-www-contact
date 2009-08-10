package WWW::Contact::BG::Mail;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.26';
our $AUTHORITY = 'cpan:FAYLAND';

use Text::vCard::Addressbook;

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from mail.bg");
    
    # to form
    $self->get('https://mail.bg') || return;
    $self->submit_form(
        form_number => 1,
        fields      => {
            imapuser  => $email,
            pass      => $password,
        }
    ) || return;
    my $content = $ua->content();
    if ($content =~ /=[\'\"]loginError/) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    
    $self->debug('Login OK');
    
    $self->get('http://mail.bg/base/addr/data.php?actionID=export&exportID=102&source=localsql') || return;
    
    $content = $ua->content();

    @contacts = $self->get_contacts_from_vcard( $content );
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_vcard {
    my ($self, $content) = @_;
    
    my $address_book = Text::vCard::Addressbook->new({ 'source_text' => $content, });
	
    my @contacts;
    foreach my $vcard ( $address_book->vcards() ) {
        push @contacts, {
            name  => $vcard->fullname(),
            email => $vcard->email(),
        };
    }

    return @contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::BG::Mail - Get contacts/addressbook from mail.bg

=head1 SYNOPSIS

    use WWW::Contact;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@mail.bg', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get contacts from mail.bg. extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<Text::vCard::Addressbook>

=head1 AUTHOR

Dimitar Petrov, C<< <mitko at datamax.bg> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dimitar Petrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
