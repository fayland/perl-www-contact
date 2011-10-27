package WWW::Contact::AOL;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.47';
our $AUTHORITY = 'cpan:FAYLAND';

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    my @contacts;
    
    my ( $username ) = split('@', $email);
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from AOL mail");
    
    # to form
    $self->get('https://my.screenname.aol.com/_cqr/login/login.psp?mcState=initialized&uitype=mini&sitedomain=registration.aol.com&authLev=1&seamless=novl&lang=en&locale=us') || return;
    $self->submit_form(
        form_name => 'AOLLoginForm',
        fields    => {
            loginId  => $username,
            password => $password,
        },
    ) || return;
    my $content = $ua->content();
    if ($content =~ /name\=\"loginId\"/) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    
    $self->debug('Login OK');
    #snsRedir("https://account.login.aol.com/opr/_cqr/data/update.psp?sitedomain=registration.aol.com&authLev=1&lang=en&locale=us&acctfixsid=oar-artifact&uitype=mini&mcAuth=%2FBcAG06o0D0AAK9OARkfR06o0HkI3xp9FQJ8VlIAAA%3D%3D");
    my ($url) = ( $content =~ /snsRedir\([\"\"]([^\'\"]+)[\"\"]/ );
    
    $ua->get($url); # usually we don't care the Response status here
    
    # but we have to skip data update form
    # skip the data update
    if ($ua->content =~ /oprFormV2/) {
        eval { $ua->submit_form( form_name => 'oprFormV2' , fields => { action => 'dataUpdateSkip' } ); };
    }
    
    $self->get('http://mail.aol.com/');
    
    # http://my.screenname.aol.com/_cqr/login/login.psp?sitedomain=sns.mail.aol.com&lang=en&locale=us&authLev=0&uitype=mini&siteState=ver%3a4%7crt%3aSTANDARD%7cat%3aSNS%7cld%3amail.aol.com%7crp%3aLite%252fToday.aspx%7cuv%3aAOL%7clc%3aen-us%7cmt%3aAOL%7csnt%3aScreenName%7csid%3a721f5d19-a18f-4f11-bf35-500d91ddf6d6&seamless=novl&loginId=&_sns_width_=174&_sns_height_=196&_sns_fg_color_=373737&_sns_err_color_=C81A1A&_sns_link_color_=0066CC&_sns_bg_color_=FFFFFF&redirType=js
    $content = $ua->{content};
    if ( $content =~ /(http\:\/\/my.screenname.aol.com\/_cqr\/login\/login.psp([^\'\"]+))/s ) {
        $self->get($1) || return;
        $content = $ua->{content};
    }
    if ( $content =~ /checkErrorAndSubmitForm/ and $content =~ /\'(http\:\/\/(.*?))\'/ ) {
        $self->get($1) || return;
    }

    my ($gSuccessPath, $aol_v) = ( $ua->content() =~ /\.com\/([^\/]+)\/(aol[^\/]*)\/en\-us/ );
    $self->get( "http://mail.aol.com/$gSuccessPath/$aol_v/en-us/Lite/Today.aspx?src=bandwidth" ) || return;

    my ($uid) = ($ua->content() =~ /user\=([^\'\&]+)[\'\&]/);
    unless ($uid) {
        $self->errstr('Wrong Password');
        return;
    }
    
    # http://mail.aol.com/39598/aol/en-us/Lite/addresslist-print.aspx?command=all&sort=FirstLastNick&sortDir=Ascending&nameFormat=FirstLastNick&user=lP9ZCc0KdY
    $ua->get(
        "http://mail.aol.com/$gSuccessPath/$aol_v/en-us/Lite/addresslist-print.aspx?command=all&sort=FirstLastNick&sortDir=Ascending&nameFormat=FirstLastNick&user=$uid"
    ) || return;

    $content = $ua->content();
    @contacts = $self->get_contacts_from_html($content);
    @contacts = grep { lc($_->{email}) ne lc($email) } @contacts; # skip himself
    
    # we don't care if it works or not, to avoid
    # Error GETing 
    eval {
        $ua->get(
            "http://mail.aol.com/$gSuccessPath/$aol_v/en-us/common/Logout.aspx"
        );
    };
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_html {
    my ($self, $content) = @_;

    my @contacts;
    my @contents = split(
        '<tr><td colspan="4"><hr class="contactSeparator"></td></tr>',
        $content );
    foreach my $c (@contents) {
        my ( $firstname, $last_name, $name )
            = ( $c =~ /fullName\"\>(\S*)\s*(\S*)\s*\<i\>\((.*?)\)/ );
        my ($email1) = (
            $c =~ /\<span\>Email 1\:\<\/span\>\s*\<span\>([^<^>]*)\<\/span\>/
        );
        my ($email2) = (
            $c =~ /\<span\>Email 2\:\<\/span\>\s*\<span\>([^<^>]*)\<\/span\>/
        );
        my $email = $email1 || $email2;
        unless ($email) {
            my ($screen_name) = ( $c
                    =~ /\<span\>Screen Name\:\<\/span\>\s*\<span\>([^<^>]*)\<\/span\>/
            );
            $email = $screen_name . '@aol.com' if ($screen_name);
        }
        next unless ($email);

        push @contacts, {
            name       => $name,
            email      => $email
        };
    }
    
    return @contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::AOL - Get contacts/addressbook from AOL Mail

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@aol.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get contacts from AOL Mail. extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
