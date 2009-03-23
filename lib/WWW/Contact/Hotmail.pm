package WWW::Contact::Hotmail;

use Moose;
extends 'WWW::Contact::Base';

use HTTP::Request::Common qw/POST/;
use HTML::TokeParser::Simple;

our $VERSION   = '0.21';
our $AUTHORITY = 'cpan:FAYLAND';

sub get_contacts {
    my ($self, $email, $password) = @_;

    # reset
    $self->errstr(undef);
    $self->debug(1);
    my @contacts;
    
    my ( $username, $domain ) = split('@', $email);
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from Hotmail");
    
    # to form
    $self->get('http://www.hotmail.com/') || return;

    my $content = $ua->content;
    # name="PPFT" id="i0327" value="Bw4Y3kJtiK6yV7ABYe!x*UuPc4ojFA3Hd9L5p5Y3YI8jpFmz3zE1oUjkvr8gGJhvdbe4KJMCYYBY3!Rvw6gnzeg2*o8UXoFzVNuEbpEyDviKY0n6INA07ZCrpC3hCNymZcj4dywAIUcIDroGGxGLX1IEUctXOCQY!GlHcjEvondo6cSF9!!tjN*6qu!X"/>';
    my ($PPFT) = ( $content =~ /name\=\"PPFT\".*?value\=\"(.*?)\"/ );
    # srf_uPost=\'https://login.live.com/ppsecure/post.srf?wa=wsignin1.0&rpsnv=10&ct=1225096129&rver=4.5.2130.0&wp=MBI&wreply=http:%2F%2Fmail.live.com%2Fdefault.aspx&id=64855&bk=1225096129\'
    my ($post_url) = ( $content =~ /srf_uPost\=\'([^\']+)\'/ );
    
    # from http://login.live.com/WLLogin_JS.srf?x=6.0.11557.0&lc=1033
    #  g_DO["compaq.net"]="https://msnia.login.live.com/ppsecure/post.srf";g_DO["hotmail.co.jp"]="https://login.live.com/ppsecure/post.srf";g_DO["hotmail.co.uk"]="https://login.live.com/ppsecure/post.srf";g_DO["hotmail.com"]="https://login.live.com/ppsecure/post.srf";g_DO["hotmail.de"]="https://login.live.com/ppsecure/post.srf";g_DO["hotmail.fr"]="https://login.live.com/ppsecure/post.srf";g_DO["hotmail.it"]="https://login.live.com/ppsecure/post.srf";g_DO["messengeruser.com"]="https://login.live.com/ppsecure/post.srf";g_DO["msn.com"]="https://msnia.login.live.com/ppsecure/post.srf";g_DO["passport.com"]="https://login.live.com/ppsecure/post.srf";g_DO["webtv.net"]="https://login.live.com/ppsecure/post.srf"; 
    if ( $domain eq 'compaq.net' or $domain eq 'msn.com' ) {
        $post_url = 'https://msnia.login.live.com/ppsecure/post.srf';
    }
    
    #  switch(g_iActiveCredtype){case 1:if(g_fLWASilentAuth==true)s.type.value=30;else s.type.value=11;break;case 2:s.type.value=12;if(s.CS.value==""){if(!SubmitCardSpace())return false;}break;case 4:s.type.value=14;if(g_fEIDSupported&&typeof g_EIDScriptDL!="undefined"){if(!EIDSubmit(s))return false;}break;case 3:s.type.value=13;
    my $type = 11;
    # XXX? It's a bit complicated. need FIX later.
    
    # try me, STUPID Microsoft always wants to get rid of US!
    $ua->request(POST $post_url, [
	    idsbho  => 1,
	    PwdPad  => 'IfYouAreReadingThisYouHaveTooMuch',
	    LoginOptions => 3,
	    CS       => undef,
	    FedState => undef,
	    PPSX => 'PassportR',
	    type => $type,
	    login  => $email,
	    passwd => $password,
	    NewUser => 1,
	    PPFT => $PPFT,
	    i1 => 0,
	    i2 => 0,
	]);
	
	# var srf_sErr=\'The e-mail address or password is incorrect. Please try again.\';
	my ( $has_error ) = ( $ua->content =~ /srf_sErr\=\'([^\']+)\'/ );
	if ( $has_error ) {
	    $self->errstr('Wrong Username or Password');
	    return;
	}

    # <html><head><script type="text/javascript">function rd(){window.location.replace("http://mail.live.com/default.aspx?wa=wsignin1.0");}function OnBack(){}</script></head><body onload="javascript:rd();"></body></html>
    my ( $url ) = ( $ua->content =~ /replace\(\"([^\"]+)\"/ );
    if ( $url ) {
        $self->get( $url ) || return;
    }
    
    # You spoke, Hotmail listened
    if ( $ua->content =~ /MessageAtLoginForm/ ) {
        $self->submit_form(
            form_name => 'MessageAtLoginForm',
        ) || return;
    }

    # TodayDefault, Our latest improvements
    my ( $maildomain ) = ( $ua->content =~ /base\s+href\=\"((.*?)\.mail\.live\.com)/ ); # <base href="http://co118w.col118.mail.live.com/" />
    my ( $uid ) = ( $ua->content =~ /n\&\#61\;(\d+)/ ); # n&#61;
    $self->get("$maildomain/mail/ContactMainLight.aspx?n=$uid") || return;

    @contacts = $self->get_contacts_from_html( $ua->content );
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_html {
    my ($self, $content) = @_;
    
    my @contacts;
    
    # cxp_ic_control_data
    my ( $data ) = ( $content =~ /cxp_ic_control_data(.*?)\}/s );
    my @lines = split(/\n/, $data);
    foreach my $line ( @lines ) {
        # ICc0:['0ea61975fb7fb339','1',['sm','si','ct'],'fayland lam','55ff0c7e-2c36-41cc-aa12-fb1db452f171','1055559157186278201','fayland\x40gmail.com','fayland\x40gmail.com','','1',[['Send e-mail','','','submitToCompose\x28\x2755ff0c7e-2c36-41cc-aa12-fb1db452f171\x27, \x27EditMessageLight.aspx\x3fn\x3d1423059530\x27\x29'],['Edit contact info','ContactEditLight.aspx\x3fContactID\x3d55ff0c7e-2c36-41cc-aa12-fb1db452f171\x26n\x3d1980367392','','','_self']]],
        my ( $email ) = ( $line =~ /\'([^\']+\\x40(.*?))\'/ );
        next unless $email;
        $email =~ s/\\x40/\@/;
        my ( $name ) = ( $line =~ /\]\,\s*\'([^\']+)\'/ );
        push @contacts, {
            email => $email,
            name  => $name,
        };
    }

    return @contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::Hotmail - Get contacts/addressbook from Hotmail/Live Mail

=head1 SYNOPSIS

    use WWW::Contact;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@hotmail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get contacts from Hotmail/Live Mail L<http://www.hotmail.com>. extends L<WWW::Contact::Base>

=head1 WARNING

Microsoft is always changing the web interface to get rid of something like us. So it might be broken soon. use it at your own risk!

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<HTML::TokeParser::Simple>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
