use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %prereq = ( 'HTML::Mason' => 1.16,
	       'Apache::Session' => 1.54,
	     );

eval { require mod_perl };
if ( $@ || $^O =~ /mac|darwin/ )
{
    $prereq{'CGI::Cookie'} = 0;
}
else
{
    $prereq{'Apache::Cookie'} = 0;
}

WriteMakefile
    ( NAME          => 'MasonX::Request::WithApacheSession',
      VERSION_FROM  => 'lib/MasonX/Request/WithApacheSession.pm',
      PREREQ_PM     => \%prereq,
      ABSTRACT_FROM => 'lib/MasonX/Request/WithApacheSession.pm',
      AUTHOR        => 'Dave Rolsky <autarch@urth.org>',
    );

package MY;

sub libscan
{
    my $self = shift;
    my $file = shift;

    return $file =~ /svn/ ? 0 : $self->SUPER::libscan($file);
}
