#
#-------------------------------------------------------------------------------
#
#  From Advisory.asc:
#
#    Fileset                 Lower Level  Upper Level  KEY
#    ----------------------------------------------------------
#    bos.ecc_client.rte      7.1.5.0      7.1.5.34     key_w_fs
#    bos.ecc_client.rte      7.2.5.0      7.2.5.1      key_w_fs
#    bos.ecc_client.rte      7.2.5.100    7.2.5.100    key_w_fs
#    bos.ecc_client.rte      7.2.5.200    7.2.5.200    key_w_fs
#    bos.ecc_client.rte      7.3.0.0      7.3.0.1      key_w_fs
#    bos.ecc_client.rte      7.3.1.0      7.3.1.0      key_w_fs
#            
#    IBM has assigned the following APARs to this problem:
#    
#    AIX Level APAR     Availability  SP        KEY
#    -----------------------------------------------------
#    7.1.5     IJ45221  **            SP12      key_w_apar
#    7.2.5     IJ44994  **            SP06      key_w_apar
#    7.3.0     IJ45224  **            SP04      key_w_apar
#    7.3.1     IJ44987  **            SP02      key_w_apar
#    
#    VIOS Level APAR    Availability  SP        KEY
#    -----------------------------------------------------
#    3.1.2      IJ45222 **            3.1.2.60  key_w_apar
#    3.1.3      IJ45223 **            3.1.3.40  key_w_apar
#    3.1.4      IJ44994 **            3.1.4.20  key_w_apar
#    
#    AIX Level  Interim Fix (*.Z)         KEY
#    ----------------------------------------------
#    7.1.5.9    IJ45221sAa.230309.epkg.Z  key_w_fix
#    7.1.5.10   IJ45221sAa.230309.epkg.Z  key_w_fix
#    7.1.5.11   IJ45221sAa.230309.epkg.Z  key_w_fix
#    7.2.5.3    IJ44994s4a.230412.epkg.Z  key_w_fix  <<-- covered elsewhere
#    7.2.5.4    IJ44994s4a.230412.epkg.Z  key_w_fix  <<-- covered elsewhere
#    7.2.5.5    IJ44994s5a.230307.epkg.Z  key_w_fix  <<-- covered elsewhere
#    7.3.0.1    IJ45224s2a.230309.epkg.Z  key_w_fix
#    7.3.0.2    IJ45224s2a.230309.epkg.Z  key_w_fix
#    7.3.0.3    IJ45224s2a.230309.epkg.Z  key_w_fix
#    7.3.1.1    IJ44987s1a.230307.epkg.Z  key_w_fix
#    
#    Please note that the above table refers to AIX TL/SP level as
#    opposed to fileset level, i.e., 7.2.5.4 is AIX 7200-05-04.
#    
#    Please reference the Affected Products and Version section above
#    for help with checking installed fileset levels.
#    
#    VIOS Level  Interim Fix (*.Z)         KEY
#    -----------------------------------------------
#    3.1.2.30    IJ45222s2a.230307.epkg.Z  key_w_fix
#    3.1.2.40    IJ45222s2a.230307.epkg.Z  key_w_fix
#    3.1.2.50    IJ45222s2a.230307.epkg.Z  key_w_fix
#    3.1.3.14    IJ45223s4a.230307.epkg.Z  key_w_fix  <<-- covered here
#    3.1.3.21    IJ45223s4a.230307.epkg.Z  key_w_fix
#    3.1.3.30    IJ45223s4a.230307.epkg.Z  key_w_fix
#    3.1.4.10    IJ44994s5a.230307.epkg.Z  key_w_fix  <<-- covered elsewhere
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij45223 {

    #  Make sure we can get to the ::staging module (deprecated ?)
    include ::staging

    #  This only applies to AIX and maybe VIOS in later versions
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ45223'

        #  Make sure we create/manage the ifix staging directory
        require aix_file_opt_ifixes

        #
        #  For now, this one only impacts VIOS, but I don't know why.
        #
        if ($::facts['aix_vios']['is_vios']) {
            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['aix_vios']['version'] == '3.1.3.14') {
                $ifixSuffix = 's4a'
                $ifixBuildDate = '230307'
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }
        }
        else {
            $ifixSuffix = 'unknown'
            $ifixBuildDate = 'unknown'
        }

        #  Add the name and suffix to make something we can find in the fact
        $ifixFullName = "${ifixName}${ifixSuffix}"

        #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
        if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

            #  Don't bother with this if it's already showing up installed
            unless ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                #  Build up the complete name of the ifix staging source and target
                $ifixStagingSource = "puppet:///modules/aix_ifix_ij45223/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"
                $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                #  Stage it
                staging::file { "$ifixStagingSource" :
                    source  => "$ifixStagingSource",
                    target  => "$ifixStagingTarget",
                    notify  => Exec["emgr-install-${ifixName}"],
                }

                #  GAG!  Use an exec resource to install it, since we have no other option yet
                exec { "emgr-install-${ifixName}":
                    path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                    command  => "/usr/sbin/emgr -e $ifixStagingTarget",
                    unless   => "/usr/sbin/emgr -l -L $ifixFullName",
                    refreshonly => true,
                }

                #  Explicitly define the dependency relationships between our resources
                File['/opt/ifixes']->Staging::File["$ifixStagingSource"]->Exec["emgr-install-${ifixName}"]

            }

        }

    }

}
