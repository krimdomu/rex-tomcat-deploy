#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Tomcat::Deploy;

=begin

=head2 SYNOPSIS

This is a (R)?ex module to ease the deployments of Tomcat Web-Apps.

=cut

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;

our $VERSION = '0.2';

require Exporter;
use base qw(Exporter);

use vars qw(@EXPORT $real_name_from_template 
                        $deploy_to 
                        $webapps_directory
                        $context_path
                        $template_file 
                        $template_pattern);

@EXPORT = qw(inject 
               deploy 
               generate_real_name 
               deploy_to 
               context_path
               webapps_directory
               template_file 
               template_search_for 
               list_versions 
               switch_to_version);

############ deploy functions ################

sub inject {
   my ($to) = @_;

   my $template_params = _get_template_params($template_file);

   mkdir("tmp");
   chdir("tmp");
   run "unzip ../$to >/dev/null 2>&1";

   for my $file (`find . -name $template_pattern`) {
      chomp $file;
      my $content = eval { local(@ARGV, $/) = ($file); $_=<>; $_; };
      for my $key (keys %$template_params) {
         my $val = $template_params->{$key};
         $content =~ s/\@$key\@/$val/g;
      }

      my $new_file_name = &$real_name_from_template($file);
      open(my $fh, ">", $new_file_name) or die($!);
      print $fh $content;
      close($fh);
   }

   run "zip -r ../$to * >/dev/null 2>&1";
   chdir("..");
   system("rm -rf tmp");
}

sub deploy {
   my ($file) = @_;

   upload ($file, "$deploy_to/$file");
   run "ln -snf $deploy_to/$file $webapps_directory/$context_path.war";
}

sub list_versions {
   return grep { ! /^\./ } list_files($deploy_to);
}

sub switch_to_version {
   my ($new_version) = @_;

   my @versions = list_versions;
   if(! grep { /$new_version/ } @versions) { print "no version found!\n"; return; }

   run "rm $webapps_directory/$context_path.war";
   sleep 10;
   run "ln -snf $deploy_to/$new_version $webapps_directory/$context_path.war";
}


############ configuration functions #############

sub generate_real_name {
   $real_name_from_template = shift;
}

sub template_file {
   $template_file = shift;
}

sub template_search_for {
   $template_pattern = shift;
}

sub deploy_to {
   $deploy_to = shift;
}

sub context_path {
   $context_path = shift;
}

sub webapps_directory {
   $webapps_directory = shift;
}


############ helper functions #############

# read the template file and return a hashref.
sub _get_template_params {
   my ($template_file) = @_;
   my @lines = eval { local(@ARGV) = ($template_file); <>; };
   my $r = {};
   for my $line (@lines) {
      next if ($line =~ m/^#/);
      next if ($line =~ m/^\s*?$/);

      my ($key, $val) = ($line =~ m/^(.*?) ?= ?(.*)$/);
      $val =~ s/^["']//;
      $val =~ s/["']$//;

      $r->{$key} = $val;
   }

   $r;
}

1;
