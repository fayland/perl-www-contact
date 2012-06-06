package WWW::Contact::GoogleContactsAPIOAuth2::MockResponse;
use Moose;

sub is_success { 1 }

package WWW::Contact::GoogleAuthSubWrapper;
use Moose;
 
our $VERSION   = '0.001';

has access_token => ( is => 'rw' );

sub login {
    my ( $self, $email, $access_token ) =  @_;
    $self->access_token( $access_token );

    # Just return a Mock Response that always has is_succes
    # to fake out GoogleContactsAPI
    return WWW::Contact::GoogleContactsAPIOAuth2::MockResponse->new;
}

sub auth_params { ( Authorization => "OAuth " . $_[0]->access_token ); }

package WWW::Contact::GoogleContactsAPIOAuth2;
use Moose;
extends 'WWW::Contact::GoogleContactsAPI';
 
our $VERSION   = '0.001';

has authsub => (
    is => 'ro',
    isa => 'WWW::Contact::GoogleAuthSubWrapper',
    lazy => 1,
    default => sub {
        WWW::Contact::GoogleAuthSubWrapper->new;
    },
);

1;

=head1 SYNOPSIS

    # Create a WWW::Contact object as usual
    my $wc = WWW::Contact->new;

    # Then we need to update the 'gmail.com' known_supplier
    # to use this GoogleContactsAPIOAuth2 module instead of the
    # default GoogleContactsAPI module.
    my $ks = $wc->known_supplier;
    $ks->{'gmail.com'} = 'GoogleContactsAPIOAuth2';
    $wc->known_supplier( $ks );

    # Pass in the access_token as the password
    # And you get the contacts using OAuth rather than AuthSub with user/pass
    my $contacts = $wc->get_contacts( $email, $access_token );

=head1 DESCRIPTION
    
    This module allows you to get google contacts using an OAuth2 token
    (Can be gotten with L<Net::Oauth2::Client>), rather than using AuthSub
    with a username/passwerd.  Google has begun warning users when third
    parties access their account with username/password, so it is becoming bad
    practice to do so.  Using OAuth avoids this problem.

    To use this module, you need to use something like L<Net::Oauth2::Client>
    to retrieve a valid access token for the desired user.  Then you need to
    replace the default C<known_supplier> for C<gmail.com> with
    L<GoogleContactsAPIOAuth2> as shown above in the synopsis.  Then you simply
    pass that C<OAuth> access token as the C<password> field when you call
    get_contacts, and you get all of the contacts using OAuth.

