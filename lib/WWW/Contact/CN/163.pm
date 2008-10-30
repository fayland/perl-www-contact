package WWW::Contact::CN::163;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.15';
our $AUTHORITY = 'cpan:FAYLAND';

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from CN::163");
    
    # to form
    $self->get('http://reg.163.com/logins.jsp?type=1&url=http://fm163.163.com/coremail/fcg/ntesdoor2?lightweight%3D1%26verifycookie%3D1%26language%3D-1%26style%3D16') || return;
    $self->submit_form(
        form_name => 'fLogin',
        fields    => {
            username => $email,
            password => $password,
        },
    ) || return;
    my $content = $ua->content();
    if ($content =~ /=[\'\"]eHint/) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    
    $self->debug('Login OK');
    
    while ( $ua->content() =~ /URL=(.*?)\"/ ) {
        $self->get($1) || return;
    }
    
    my ($sid) = ( $ua->content() =~ /sid\=(\w+)(\"|\&)/ );
    unless ( $sid ) {
        $self->errstr('Unknown Error');
        return;
    }
    
    $self->get("/coremail/fcg/ldvcapp?funcid=xportadd&sid=$sid") || return;
    if ( $ua->content() !~ /outport/ ) {
        $self->errstr('Wrong Password');
        return;
    }

    $self->submit_form(
        form_name => 'outport',
        fields    => { outformat => 8, },
        button    => 'outport.x',
    ) || return;

    $content = $ua->content();
    @contacts = $self->get_contacts_from_html($content);
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_html {
    my ($self, $content) = @_;

    my @contacts;
    
    my @contents = split( /\n/, $content );
    foreach my $con (@contents) {
        my @cons  = split( /\,/, $con );
        my $email = $cons[3];
        my $name  = $cons[4];
        $email =~ s/\"//isg;
        $name  =~ s/\"//isg;
        next unless ( $email =~ /\@/ );
        my $c = { name => $name, email => $email };
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

get contacts from mail.163.com. extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<HTML::TokeParser::Simple>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
