package CloudForecast::Data::Acpitemperature;

use CloudForecast::Data -base;

rrds map { [ $_, 'GAUGE' ] } qw /temp/;
graphs 'temp' => 'ACPI Temperature';

title {
    my $c = shift;
    my $title = "ACPI Temp";
    return $title;
};

sysinfo {
    my $c = shift;
    $c->ledge_get('sysinfo') || [];
};

fetcher {
    my $c = shift;
    my $temp;

    ### find temperature file
    my @temp_files;
    my @temp_files_proc = glob '/proc/acpi/thermal_zone/*/temperature';
    my @temp_files_sys  = glob '/sys/class/thermal/thermal_zone*/temp';

    if (@temp_files_proc) {
        @temp_files = @temp_files_proc;

        if (scalar(@temp_files) > 1) {
            CloudForecast::Log->warn("more then one temp files found. decide to use first file.");
        }

        $c->ledge_set('sysinfo', [ file => $temp_files[0] ]);

        open my $tempf, '<', $temp_files[0] or die $!;
        my $line = <$tempf>;    # <= "temperature:             57 C"
        close $tempf;
        ($temp) = (split(/\s*:\s*/, $line))[1] =~ /([\d.]+)/;
    } elsif (@temp_files_sys) {
        @temp_files = @temp_files_sys;

        if (scalar(@temp_files) > 1) {
            CloudForecast::Log->warn("more then one temp files found. decide to use first file.");
        }

        $c->ledge_set('sysinfo', [ file => $temp_files[0] ]);

        open my $tempf, '<', $temp_files[0] or die $!;
        my $line = <$tempf>;    # <= "69000"
        close $tempf;
        ($temp) = $line =~ /([\d.]+)/;
        $temp = $temp / 1000;
    } else {
        CloudForecast::Log->warn("cannot find temperature file.");
        return [undef];
    }

    return [$temp];
};

__DATA__
@@ temp
DEF:my1=<%RRD%>:temp:AVERAGE
LINE1:my1#00cf00:Temperature
GPRINT:my1:LAST:Cur\: %4.1lf
GPRINT:my1:AVERAGE:Ave\: %4.1lf
GPRINT:my1:MAX:Max\: %4.1lf
GPRINT:my1:MIN:Min\: %4.1lf [C]\c

