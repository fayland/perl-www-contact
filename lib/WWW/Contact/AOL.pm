package WWW::Contact::AOL;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.16';
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
    $self->get('https://my.screenname.aol.com/_cqr/login/login.psp?mcState=initialized&uitype=mini&sitedomain=sns.webmail.aol.com&authLev=1&seamless=novl&lang=en&locale=us') || return;
    $self->submit_form(
        form_name => 'AOLLoginForm',
        fields    => {
            loginId  => $username,
            password => $password,
        },
    ) || return;
    my $content = $ua->content();
    if ($content =~ /name\=\"loginId\"/) {
        $self->errstr('Wrong Password');
        return;
    }
    
    $self->debug('Login OK');

    my ($url) = ( $content =~ /\'(http\:\/\/(.*?))\'/ );
    $self->get($url) || return;
    $self->get('http://webmail.aol.com/');
    $content = $ua->content();
    if ( $content =~ /checkErrorAndSubmitForm/ and $content =~ /\'(http\:\/\/(.*?))\'/ ) {
        $url = $1;
        $self->get($url) || return;
    }

    my ($gSuccessPath) = ( $ua->content() =~ /\.com\/([^\/]+)\/aol/ );
    $self->get( "http://webmail.aol.com/$gSuccessPath/aol/en-us/Lite/MsgList.aspx" ) || return;

    my ($uid) = ($ua->content() =~ /user\=([^\'\&]+)[\'\&]/);
    unless ($uid) {
        $self->errstr('Wrong Password');
        return;
    }
    
    # http://webmail.aol.com/39598/aol/en-us/Lite/addresslist-print.aspx?command=all&sort=FirstLastNick&sortDir=Ascending&nameFormat=FirstLastNick&user=lP9ZCc0KdY
    $ua->get(
        "http://webmail.aol.com/$gSuccessPath/aol/en-us/Lite/addresslist-print.aspx?command=all&sort=FirstLastNick&sortDir=Ascending&nameFormat=FirstLastNick&user=$uid"
    ) || return;

    $content = $ua->content();
    @contacts = $self->get_contacts_from_html($content);
    
    # we don't care if it works or not, to avoid
    # Error GETing http://webmail-vma.webmail.aol.com/22250/aol/en-us/Shared/Logout.aspx: Forbidden at lib/WWW/Contact/AOL.pm line 64
    eval {
        $ua->get(
            "http://webmail-vma.webmail.aol.com/22250/aol/en-us/Shared/Logout.aspx"
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
