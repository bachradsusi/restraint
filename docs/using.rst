Using Restraint
===============

Running in Beaker
-----------------

Beaker will use restraint by default if you are running Red Hat Enterprise Linux
version 8 or later or if you are running Fedora version 29 or later.

To use Restraint in Beaker for earlier versions of Red Hat Enterprise Linux or
Fedora, you will need to specify 'restraint' as the harness::

 <recipe ks_meta="harness=restraint">
 <repos>
  <repo name="restraint"
        url="https://beaker-project.org/yum/harness/Fedora29/"/>
 </repos>
  .
  .
  .
 </recipe>

If you have tasks/tests that were written for legacy RHTS (Red Hat Test System)
you can install the restraint-rhts sub-package which will bring in the legacy
commands so that your tests will execute properly. Some tasks/tests have also
been written with beakerlib. Here is an example recipe node that will install
both for you::

 <recipe ks_meta="harness='restraint-rhts beakerlib'">
 .
 .
 .
 </recipe>

If you are using Beaker command line workflows use these command line options::

 bkr <WORKFLOW> --ks-meta="harness=restraint" --repo https://beaker-project.org/yum/harness/Fedora29/

If you need RHTS compatibility and/or beakerlib you can add it here as well::

 bkr <WORKFLOW> --ks-meta="harness='restraint-rhts beakerlib'" --repo https://beaker-project.org/yum/harness/Fedora29/

.. _standalone:

Running Standalone
-------------------

Restraint can run on its own without Beaker, this is handy when you are
developing a test and would like quicker turn around time. Before Restraint you
either ran the test locally and hoped it would act the same when run inside
Beaker or dealt with the slow turn around of waiting for Beaker to schedule,
provision and finally run your test. This is less then ideal when you are
actively developing a test.

You still need a job XML file which tells Restraint what tasks should be run.
Here is an example where we run three tests directly from git::

 <?xml version="1.0"?>
 <job>
   <recipeSet>
     <recipe id="1">
       <task name="/kernel/performance/fs_mark">
         <fetch url="git://fedorapeople.org/home/fedora/bpeck/public_git/tests.git?master#kernel/performance/fs_mark"/>
       </task>
       <task name="/kernel/misc/gdb-simple">
         <fetch url="git://fedorapeople.org/home/fedora/bpeck/public_git/tests.git?master#kernel/misc/gdb-simple"/>
       </task>
       <task name="/kernel/standards/usex" role="None">
        <fetch url="git://fedorapeople.org/home/fedora/bpeck/public_git/tests.git#kernel/standards/usex"/>
       </task>
     </recipe>
   </recipeSet>
 </job>

Tell Restraint to run a job::

 % restraint --job /path/to/job.xml

You probably don't want to run restraintd on the machine you use for day to day
activity. Some tests can be destructive or just make unfriendly changes to your
system. Restraint allows you to run tasks on a remote system. This means you
can have the task git repo on your development workstation and verify the
results on your test system. In order for this to work your git repo and the
recipe XML need to be accessible to your test system. Be sure to have the
restraint-client package installed on the machine you will be running the
restraint command from

Here is an example::

 % restraint --host 1=addressOfMyTestSystem.example.com:8081 --job /path/to/job.xml

This will connect to restraintd running on addressOfMyTestSystem.example.com
and tell it to run the recipe with id="1" from this machine. Also remember that
the tasks which are referenced inside of the recipe need to be accessible a
well. Here is the output::

 restraint --host 1=addressOfRemoteSystem:8081 --job simple_job.xml -v
 Using ./simple_job.07 for job run
 * Fetching recipe: http://192.168.1.198:8000/recipes/07/
 * Parsing recipe
 * Running recipe
 *  T:   1 [/kernel/performance/fs_mark                     ] Running
 **      1 [Default                                         ] PASS
 **      2 [Random                                          ] PASS
 **      3 [MultiDir                                        ] PASS
 **      4 [Random_MultiDir                                 ] PASS
 *  T:   1 [/kernel/performance/fs_mark                     ] Completed: PASS
 *  T:   2 [/kernel/misc/gdb-simple                         ] Running
 **      5 [/kernel/misc/gdb-simple                         ] PASS Score: 0
 *  T:   2 [/kernel/misc/gdb-simple                         ] Completed: PASS
 *  T:   3 [/kernel/standards/usex                          ] Running
 **  :   6 [/kernel/standards/usex                          ] PASS
 *  T:   3 [/kernel/standards/usex                          ] Completed: PASS

All results will be stored in the job run directory which is 'simple_job.07'
for this run. In this directory you will find 'job.xml' which has all the
results and references to all the task logs. You can convert this into HTML
with the following command::

 % xsltproc job2html.xml simple_job.07/job.xml >simple_job.07/index.html

``job2html.xml`` is found in Restraint's ``client`` directory.

Running in Beaker and Standalone
--------------------------------

Sometimes the tests that I am developing can be destructive to the system so I
don't want to run them on my development box. Or the test is specific to an
architecture so I can't use a VM for it on my machine. These are cases where
it's really handy to use a combination of Beaker for provisioning and
Standalone for executing the tests.

First step is to run the following workflow to reserve a system in Beaker::

 <job><whiteboard>restraint reservesys</whiteboard>
  <recipeSet>
   <recipe ks_meta="harness=restraint" id="1">
    <distroRequires>
     <and>
      <distro_name op="=" value="Fedora-20"/>
      <distro_arch op="=" value="x86_64"/>
     </and>
    </distroRequires>
    <hostRequires/>
    <repos>
     <repo name="myrepo_0" url="http://copr-be.cloud.fedoraproject.org/results/bpeck/restraint/fedora-20-x86_64"/>
    </repos>
    <task name="/distribution/install" role="STANDALONE" />
    <task name="/distribution/reservesys" role="None">
     <fetch url="git://fedorapeople.org/home/fedora/bpeck/public_git/tests.git#distribution/reservesys"/>
    </task>
   </recipe>
  </recipeSet>
 </job>

This will reserve a ppc64 system running Fedora20. The /distribution/reservesys
task will email the submitter of the job when run so you know the system is
available. By default the reservesys task will give you access to the system
for 24 hours, after that the external watchdog will reclaim the system. You can
extend it using extendtesttime.sh on the system. Finally It will also run a
second instance of restraintd on port 8082 which you can then connect to with
the Restraint client running on your developer machine.::

 % restraint --host 1=FQDN.example.com:8082 --job simple_job.xml

If the task you are developing doesn't work as expected you can make changes
and try again. Just remember to push your changes to git, the system under test
will pull from the git URL you put in your job XML.
