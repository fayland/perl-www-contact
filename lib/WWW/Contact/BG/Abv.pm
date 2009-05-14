package WWW::Contact::BG::Abv;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.26';

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from abv");
    
    # to form
    # with_fields is used, 'cause username and password are not ids
    $self->get('http://www.abv.bg/') || return;
    $self->submit_form(
        form_number => 1,
        with_fields  => {
            username  => $email,
            password  => $password,
        },
    ) || return;

    my $content = $ua->content();
    if ($content =~ /login_help/) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    
    my $base;
    if ( $content =~ m/replace\("(.*)"\)/g ) {
        my $fw = $1;
        my $headers = $ua->head( $fw );
        my $c = $headers->previous()->header( 'set-cookie' );
        if ( $c =~ m/uhost=([a-zA-Z0-9]+\.abv.bg)/i ) {
            $base = $1;
        } else {
            $self->errstr( 'Could not match base' );
            return;
        }
    } else {
        $self->errstr( 'Could not match address' );
        return;
    }

    $self->debug('Login OK');
   
    # FIXME: ssl connection is better
    $ua->get( "http://$base/app/servlet/addrimpex?action=EXPORT&program=40" );
      
    # The content is CSV file
    $content = $ua->content();
   
    while ( $content
                # $1 = fname, $2=lname, $3 = "lname, fname', $4 = email
        =~ /^(.*?)\,(.*?)\,\"(.*?\,.*?)\"\,.*?\,(.*?)\,\,{31}/mg
                ) {
        next unless $4;

        my $email = $4;
        my $name = ( $1 or $2 ) ? "$1 $2" : $3;
        push @contacts, {
            name       => $name,
            email      => $email,
        };
    }

    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::BG::Abv - Get contacts/addressbook from Abv.bg

=head1 SYNOPSIS

    use WWW::Contact;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@abv.bg', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get contacts from Abv.bg, gbg.bg, gyuvectch.bg

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>

=head1 AUTHOR

Dimitar Petrov, C<< <mitko at datamax.bg> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dimitar Petrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
