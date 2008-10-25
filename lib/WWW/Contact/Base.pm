package WWW::Contact::Base;

use Moose;
use Moose::Util::TypeConstraints;
use Carp qw/croak/;
use Data::Dumper;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:FAYLAND';

my $sub_verbose = sub {
    my $msg = shift;
    $msg =~ s/\s+$//;
    print STDERR "$msg\n";
};
subtype 'Verbose'
    => as 'CodeRef'
    => where { 1; };
coerce 'Verbose'
    => from 'Int'
    => via {
        if ($_) {
            return $sub_verbose;
        } else {
            return sub { 0 };
        }
    };

has 'verbose' => ( is => 'rw', isa => 'Verbose', coerce => 1, default => 0 );
has 'ua_class' => ( is => 'rw', isa => 'Str', default => 'WWW::Mechanize' );
has 'ua' => (
    is => 'rw',
    isa => 'Object',
    lazy => 1,
    default => sub {
        my $class = (shift)->ua_class;
        eval "use $class";
        croak $@ if ($@);
        $class->new(
            agent       => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
            cookie_jar  => {},
            stack_depth => 1,
            timeout     => 60,
        );
    }
);

has 'errstr' => ( is => 'rw', isa => 'Maybe[Str]' );

sub debug {
    my $self = shift;
    
    return unless $self->verbose;
    $self->verbose->(@_);
}

sub debug_to_file {
    my ($self, $file) = @_;
    
    return unless $self->verbose;
    
    open(my $fh, '>', $file);
    print $fh Dumper(\$self->ua);
    close($fh);
}

sub get_contacts_from_outlook_csv {
    my ($self, $csv) = @_;
    
    my @contacts;
    
    # Name,E-mail Address,Notes,
    my @lines = split(/\n/, $csv);
    shift @lines; # skip the first line
    foreach my $line (@lines) {
        my @cols = split(',', $line);
        next if ( $cols[1] !~ /\@/ ); # skip unknow lines
        push @contacts, {
            name  => $cols[0],
            email => $cols[1]
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

sub get {
    my $self = shift;
    
    my $resp = $self->ua->get(@_);
    unless ( $resp->is_success ) {
        $self->errstr( $resp->as_string() );
        return;
    }
    return 1;
}

sub submit_form {
    my $self = shift;
    
    my $resp = $self->ua->submit_form(@_);
    unless ( $resp->is_success ) {
        $self->errstr( $resp->as_string() );
        return;
    }
    return 1;
}

no Moose;
no Moose::Util::TypeConstraints;

1;
__END__

=head1 NAME

WWW::Contact::Base - Base module for WWW::Contact::*

=head1 SYNOPSIS

    use WWW::Contact::MyMail;
    
    use Moose;
    extends 'WWW::Contact::Base';
    
    sub get_contacts {
        my ($self, $email, $password) = @_;
        
        # reset
        $self->errstr(undef);
        my @contacts;
        
        my $ua = $self->ua;
        $self->debug("start get_contacts from MyMail");
        
        # get contacts
        
        return wantarray ? @contacts : \@contacts;
    }

=head1 DESCRIPTION

This module is mainly for you to write your own WWW::Contact::* (and used in my WWW::Contact::)

=head1 METHODS

=over 4

=item ua

an instance of L<WWW::Mechanize>

    $self->ua->get('http://www.google.com');

If u want to use WWW::Mechanize::* instead of WWW::Mechanize, try

    extends 'WWW::Contact::Base';
    has '+ua_class' => ( default => 'WWW::Mechanize::GZip' );

=item verbose

turn on debug, default is off

    $self->verbose(1); # turn on
    $self->verbose(0); # turn off

=item debug

write debug info depends on $self->verbose

    $self->debug("start get_contacts from MyMail");

=item debug_to_file($file)

Dumper(\$self->ua) to $file

    $self->debug_to_file($file)

=item get

a wrapper of $self->ua->get, with $resp->is_success check

    $self->get('http://www.google.com');

=item submit_form

a wrapper of $self->ua->submit_form, with $resp->is_success check

    $self->submit_form(
        form_number => 1,
        fields      => {
            Email  => $email,
            Passwd => $password,
        }
    );

=back

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<Moose>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

