package WWW::Contact::Unknown;

use Moose;
extends 'WWW::Contact::Base';

sub get_contacts {
    my ($self, $email, $password) = @_;
    
    # reset
    $self->errstr(undef);
    
    if ($email eq 'a@a.com' and $password eq 'b') {
        $self->errstr('error!');
        return;
    }
    
    my @contacts = ( {
        email => 'b@b.com',
        name => 'b',
    }, {
        email => 'c@c.com',
        name => 'c'
    } );
    return wantarray ? @contacts : \@contacts;
}

1;