package WWW::Contact::CN::163;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.28';
our $AUTHORITY = 'cpan:FAYLAND';

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from CN::163");
    
    # to form
    $self->get('https://reg.163.com/logins.jsp?type=1&product=mail163&url=http://entry.mail.163.com/coremail/fcg/ntesdoor2?lightweight%3D1%26verifycookie%3D1%26language%3D-1%26style%3D') || return;
    $self->submit_form(
        form_name => 'fLogin',
        fields    => {
            username => $email,
            password => $password,
        },
    ) || return;
    my $content = $ua->content();
    if ($content =~ /fLogin/) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    
    $self->debug('Login OK');
    
    while ( $ua->content() =~ /URL=(.*?)\"/ ) {
        my $url = $1;
        if ( $self->{ua}->content() =~ /window.location.replace\(\"(.*?)\"/ ) {
            $self->get($1) || return;
        } else {
            $self->get($url) || return;
        }
    }
    
    my ($sid) = ( $ua->content() =~ /sid\=(\w+)(\"|\&)/ );
    unless ( $sid ) {
        $self->errstr('Unknown Error');
        return;
    }
    
    $self->get("/jy3/address/addrprint.jsp?sid=$sid") || return;
    $content = $ua->content();
    @contacts = $self->get_contacts_from_html($content);
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_html {
    my ($self, $content) = @_;

    my @contents = split('class="gTitleSub', $content);
    shift @contents;

    my @contacts;
    foreach my $con (@contents) {
        my ( $name, $email );
        if ( $con =~ /mTT\"\>(.*?)\</ ) {
            $name = $1;
        }
        if ( $con =~ /td\>\s*((.*?)\@(.*?))\</ ) {
            $email = $1;
        }
        next unless $email;
        
        my $c = { name => $name || $email, email => $email };
        push @contacts, $c;
    }

    return @contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::CN::163 - Get contacts/addressbook from mail.163.com

=head1 SYNOPSIS

    use WWW::Contact;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@163.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get contacts from mail.163.com. Extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<HTML::TokeParser::Simple>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
