use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex-Tomcat-Deploy',
   VERSION_FROM => 'lib/Rex/Tomcat/Deploy.pm',
   PREREQ_PM => {'rex' => '0.1.1'},
   LICENSE => 'perl'
);

