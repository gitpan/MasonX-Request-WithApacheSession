use strict;

use Cwd;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec;

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

my $clean = '';

# only bother with this stuff for the maintainer
if ( -d '.svn' )
{
    use lib 't/lib';
    require Apache::test;

    my %p = Apache::test->get_test_params();

    if (%p)
    {
        my $cwd = cwd();
        my $conf_file = File::Spec->catfile( $cwd, 't', 'httpd.conf' );
        my $apache_dir = dirname($conf_file);
        $apache_dir =~ s,/$,,;

        my $comp_root = File::Spec->catdir( $apache_dir, 'comps' );
        my $data_dir = File::Spec->catdir( $apache_dir, 'data' );

        unless ( -d $comp_root )
        {
            mkdir $comp_root, 0755
                or die "Can't make dir '$comp_root': $!";
        }

        unless ( -d $data_dir )
        {
            mkdir $data_dir, 0755
                or die "Can't make dir '$data_dir': $!";
        }

        my $session_dir = File::Spec->tmpdir . '/sessions';

        unless ( -d $session_dir )
        {
            mkdir $session_dir, 0755
                or die "Can't make dir '$session_dir': $!";
        }

        my $base_config = <<"EOF";

  PerlSetVar  MasonSessionClass  Apache::Session::File
  PerlSetVar  MasonSessionDirectory      $session_dir
  PerlSetVar  MasonSessionLockDirectory  $session_dir

  PerlSetVar  MasonCompRoot  $comp_root
  PerlSetVar  MasonDataDir   $data_dir

  SetHandler  perl-script
  PerlHandler HTML::Mason::ApacheHandler
EOF

        my $include = <<"EOF";
<Location /comps/resend/>
  PerlSetVar  MasonRequestClass  MasonX::Request::WithApacheSession
  PerlSetVar  MasonSessionUseCookie  1

$base_config
</Location>

<Location /comps/no_resend/>
  PerlSetVar  MasonRequestClass  MasonX::Request::WithApacheSession
  PerlSetVar  MasonSessionUseCookie     1
  PerlSetVar  MasonSessionCookieResend  0

$base_config
</Location>

<Location /comps/no_cookie/>
  PerlSetVar  MasonRequestClass  MasonX::Request::WithApacheSession
  PerlSetVar  MasonSessionUseCookie  0

$base_config
</Location>
EOF

        local $^W;
        Apache::test->write_httpd_conf
            ( %p,
              include => $include
            );

        $clean .=
            ( join ' ',
              map { "$apache_dir/$_" }
              qw( httpd.conf error_log httpd httpd.pid )
            );

        $clean .= " $comp_root $data_dir $session_dir";
    }
}

WriteMakefile
    ( NAME          => 'MasonX::Request::WithApacheSession',
      VERSION_FROM  => 'lib/MasonX/Request/WithApacheSession.pm',
      PREREQ_PM     => \%prereq,
      ABSTRACT_FROM => 'lib/MasonX/Request/WithApacheSession.pm',
      AUTHOR        => 'Dave Rolsky <autarch@urth.org>',
      clean         => { FILES => $clean },
    );

package MY;

sub libscan
{
    my $self = shift;
    my $file = shift;

    return $file =~ /svn/ ? 0 : $self->SUPER::libscan($file);
}
