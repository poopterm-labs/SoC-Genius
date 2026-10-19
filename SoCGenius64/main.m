#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <math.h>
#import <mach/mach.h>
#import <mach/processor_info.h>
#define GLES_SILENCE_DEPRECATION 1
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <sys/mount.h>
#import <CoreMotion/CoreMotion.h>

static NSString *MachineIdentifier(void) {
    size_t size = 0; sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    if (!size) return @"Unknown";
    char *machine = malloc(size);
    if (!machine) return @"Unknown";
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *value = [NSString stringWithUTF8String:machine]; free(machine);
    return value ? value : @"Unknown";
}
static NSString *FriendlyModelName(NSString *machine) {
    NSDictionary *models = [NSDictionary dictionaryWithObjectsAndKeys:
        @"iPhone 5 (GSM)", @"iPhone5,1", @"iPhone 5 (CDMA)", @"iPhone5,2",
        @"iPhone 6 Plus", @"iPhone7,1", @"iPhone 6", @"iPhone7,2",
        @"iPhone 11", @"iPhone12,1", @"iPhone 15 Pro Max", @"iPhone16,2", nil];
    NSString *name = [models objectForKey:machine]; return name ? name : machine;
}
static NSString *DeviceProfile(NSString *machine) {
    static NSDictionary *profiles = nil;
    if (!profiles) profiles = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"iPhone|Samsung S5L8900|412 MHz|", @"iPhone1,1",
        @"iPhone 3G|Samsung S5L8900|412 MHz|", @"iPhone1,2",
        @"iPhone 3GS|Samsung S5PC100|600 MHz|Apple_SoC_S5L8920", @"iPhone2,1",
        @"iPhone 4|Apple A4|800 MHz|Apple_A4_Chip", @"iPhone3,1", @"iPhone 4|Apple A4|800 MHz|Apple_A4_Chip", @"iPhone3,2", @"iPhone 4|Apple A4|800 MHz|Apple_A4_Chip", @"iPhone3,3",
        @"iPhone 4S|Apple A5|800 MHz|Apple_A5_Chip", @"iPhone4,1",
        @"iPhone 5|Apple A6|1.3 GHz|Apple_A6_Chip|4.0", @"iPhone5,1", @"iPhone 5|Apple A6|1.3 GHz|Apple_A6_Chip|4.0", @"iPhone5,2",
        @"iPhone 5s|Apple A7|1.3 GHz|Apple_A7_Chip|4.0", @"iPhone6,1", @"iPhone 5s|Apple A7|1.3 GHz|Apple_A7_Chip|4.0", @"iPhone6,2",
        @"iPhone 6 Plus|Apple A8|1.4 GHz|Apple_A8_Chip|5.5", @"iPhone7,1", @"iPhone 6|Apple A8|1.4 GHz|Apple_A8_Chip|4.7", @"iPhone7,2",
        @"iPhone 6s|Apple A9|1.85 GHz|Apple_A9_Chip|4.7", @"iPhone8,1", @"iPhone 6s Plus|Apple A9|1.85 GHz|Apple_A9_Chip|5.5", @"iPhone8,2",
        @"iPhone SE (1st generation)|Apple A9|1.85 GHz|Apple_A9_Chip|4.0", @"iPhone8,4",
        @"iPhone 7|Apple A10 Fusion|2.34 GHz|Apple_A10_Fusion_Chip|4.7", @"iPhone9,1", @"iPhone 7|Apple A10 Fusion|2.34 GHz|Apple_A10_Fusion_Chip|4.7", @"iPhone9,3",
        @"iPhone 7 Plus|Apple A10 Fusion|2.34 GHz|Apple_A10_Fusion_Chip|5.5", @"iPhone9,2", @"iPhone 7 Plus|Apple A10 Fusion|2.34 GHz|Apple_A10_Fusion_Chip|5.5", @"iPhone9,4",
        @"iPhone 8|Apple A11 Bionic|2.39 GHz|Apple_A11_Chip|4.7", @"iPhone10,1", @"iPhone 8|Apple A11 Bionic|2.39 GHz|Apple_A11_Chip|4.7", @"iPhone10,4",
        @"iPhone 8 Plus|Apple A11 Bionic|2.39 GHz|Apple_A11_Chip|5.5", @"iPhone10,2", @"iPhone 8 Plus|Apple A11 Bionic|2.39 GHz|Apple_A11_Chip|5.5", @"iPhone10,5",
        @"iPhone X|Apple A11 Bionic|2.39 GHz|Apple_A11_Chip|5.8", @"iPhone10,3", @"iPhone X|Apple A11 Bionic|2.39 GHz|Apple_A11_Chip|5.8", @"iPhone10,6",
        @"iPhone XR|Apple A12 Bionic|2.49 GHz|Apple_A12_Chip|6.1", @"iPhone11,8", @"iPhone XS|Apple A12 Bionic|2.49 GHz|Apple_A12_Chip|5.8", @"iPhone11,2",
        @"iPhone XS Max|Apple A12 Bionic|2.49 GHz|Apple_A12_Chip|6.5", @"iPhone11,4", @"iPhone XS Max|Apple A12 Bionic|2.49 GHz|Apple_A12_Chip|6.5", @"iPhone11,6",
        @"iPhone 11|Apple A13 Bionic|2.66 GHz|Apple_A13_Bionic_Chip|6.1", @"iPhone12,1", @"iPhone 11 Pro|Apple A13 Bionic|2.66 GHz|Apple_A13_Bionic_Chip|5.8", @"iPhone12,3", @"iPhone 11 Pro Max|Apple A13 Bionic|2.66 GHz|Apple_A13_Bionic_Chip|6.5", @"iPhone12,5",
        @"iPhone 12 mini|Apple A14 Bionic|3.00 GHz|Apple_A14_Chip|5.4", @"iPhone13,1", @"iPhone 12|Apple A14 Bionic|3.00 GHz|Apple_A14_Chip|6.1", @"iPhone13,2", @"iPhone 12 Pro|Apple A14 Bionic|3.00 GHz|Apple_A14_Chip|6.1", @"iPhone13,3", @"iPhone 12 Pro Max|Apple A14 Bionic|3.00 GHz|Apple_A14_Chip|6.7", @"iPhone13,4",
        @"iPhone 13 Pro|Apple A15 Bionic|3.23 GHz|Apple_A15_Chip|6.1", @"iPhone14,2", @"iPhone 13 Pro Max|Apple A15 Bionic|3.23 GHz|Apple_A15_Chip|6.7", @"iPhone14,3",
        @"iPhone 13 mini|Apple A15 Bionic|3.23 GHz|Apple_A15_Chip|5.4", @"iPhone14,4", @"iPhone 13|Apple A15 Bionic|3.23 GHz|Apple_A15_Chip|6.1", @"iPhone14,5",
        @"iPhone 14|Apple A15 Bionic|3.23 GHz|Apple_A15_Chip|6.1", @"iPhone14,7", @"iPhone 14 Plus|Apple A15 Bionic|3.23 GHz|Apple_A15_Chip|6.7", @"iPhone14,8",
        @"iPhone 14 Pro|Apple A16 Bionic|3.46 GHz|Apple_A16_Chip|6.1", @"iPhone15,2", @"iPhone 14 Pro Max|Apple A16 Bionic|3.46 GHz|Apple_A16_Chip|6.7", @"iPhone15,3",
        @"iPhone 15|Apple A16 Bionic|3.46 GHz|Apple_A16_Chip|6.1", @"iPhone15,4", @"iPhone 15 Plus|Apple A16 Bionic|3.46 GHz|Apple_A16_Chip|6.7", @"iPhone15,5",
        @"iPhone 15 Pro|Apple A17 Pro|Not published|Apple_A17_Pro_Chip|6.1", @"iPhone16,1", @"iPhone 15 Pro Max|Apple A17 Pro|Not published|Apple_A17_Pro_Chip|6.7", @"iPhone16,2",
        @"iPod touch (1st generation)|Samsung S5L8900|412 MHz|", @"iPod1,1",
        @"iPod touch (2nd generation)|Samsung S5L8720|533 MHz|", @"iPod2,1",
        @"iPod touch (3rd generation)|Samsung S5L8922|600 MHz|S5L8922", @"iPod3,1",
        @"iPod touch (4th generation)|Apple A4|800 MHz|Apple_A4_Chip", @"iPod4,1",
        @"iPod touch (5th generation)|Apple A5|800 MHz|Apple_A5_Chip", @"iPod5,1",
        @"iPad|Apple A4|1 GHz|Apple_A4_Chip", @"iPad1,1",
        @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,1", @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,2", @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,3", @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,4",
        @"iPad (3rd generation)|Apple A5X|1 GHz|Apple_A5X_Chip", @"iPad3,1", @"iPad (3rd generation)|Apple A5X|1 GHz|Apple_A5X_Chip", @"iPad3,2", @"iPad (3rd generation)|Apple A5X|1 GHz|Apple_A5X_Chip", @"iPad3,3",
        @"iPad (4th generation)|Apple A6X|1.4 GHz|Apple_A6X_chip", @"iPad3,4", @"iPad (4th generation)|Apple A6X|1.4 GHz|Apple_A6X_chip", @"iPad3,5", @"iPad (4th generation)|Apple A6X|1.4 GHz|Apple_A6X_chip", @"iPad3,6",
        @"iPad mini|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,5", @"iPad mini|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,6", @"iPad mini|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,7",
        @"iPad Pro 11-inch (3rd generation)|Apple M1|Not published|Apple_M1_Chip|11.0", @"iPad13,4", @"iPad Pro 11-inch (3rd generation)|Apple M1|Not published|Apple_M1_Chip|11.0", @"iPad13,5", @"iPad Pro 11-inch (3rd generation)|Apple M1|Not published|Apple_M1_Chip|11.0", @"iPad13,6", @"iPad Pro 11-inch (3rd generation)|Apple M1|Not published|Apple_M1_Chip|11.0", @"iPad13,7",
        @"iPad Pro 12.9-inch (5th generation)|Apple M1|Not published|Apple_M1_Chip|12.9", @"iPad13,8", @"iPad Pro 12.9-inch (5th generation)|Apple M1|Not published|Apple_M1_Chip|12.9", @"iPad13,9", @"iPad Pro 12.9-inch (5th generation)|Apple M1|Not published|Apple_M1_Chip|12.9", @"iPad13,10", @"iPad Pro 12.9-inch (5th generation)|Apple M1|Not published|Apple_M1_Chip|12.9", @"iPad13,11",
        @"iPad Air (5th generation)|Apple M1|Not published|Apple_M1_Chip|10.9", @"iPad13,16", @"iPad Air (5th generation)|Apple M1|Not published|Apple_M1_Chip|10.9", @"iPad13,17",
        @"iPad Pro 11-inch (4th generation)|Apple M2|Not published|Apple_M2_Chip|11.0", @"iPad14,3", @"iPad Pro 11-inch (4th generation)|Apple M2|Not published|Apple_M2_Chip|11.0", @"iPad14,4",
        @"iPad Pro 12.9-inch (6th generation)|Apple M2|Not published|Apple_M2_Chip|12.9", @"iPad14,5", @"iPad Pro 12.9-inch (6th generation)|Apple M2|Not published|Apple_M2_Chip|12.9", @"iPad14,6",
        @"iPad Air 11-inch (M2)|Apple M2|Not published|Apple_M2_Chip|11.0", @"iPad14,8", @"iPad Air 11-inch (M2)|Apple M2|Not published|Apple_M2_Chip|11.0", @"iPad14,9",
        @"iPad Air 13-inch (M2)|Apple M2|Not published|Apple_M2_Chip|13.0", @"iPad14,10", @"iPad Air 13-inch (M2)|Apple M2|Not published|Apple_M2_Chip|13.0", @"iPad14,11", nil];
    return [profiles objectForKey:machine];
}
static NSString *ProfileField(NSString *machine, NSUInteger field) {
    NSArray *parts = [[DeviceProfile(machine) componentsSeparatedByString:@"|"] retain];
    NSString *value = (parts && parts.count > field) ? [parts objectAtIndex:field] : @"Unknown";
    NSString *result = [[value copy] autorelease]; [parts release]; return result;
}
static NSString *PixelResolution(void) {
    UIScreen *screen=[UIScreen mainScreen]; CGRect pixels=screen.bounds;
    if ([screen respondsToSelector:@selector(nativeBounds)]) pixels=screen.nativeBounds;
    else if ([screen respondsToSelector:@selector(scale)]) { pixels.size.width*=screen.scale; pixels.size.height*=screen.scale; }
    return [NSString stringWithFormat:@"%.0f × %.0f pixels",pixels.size.width,pixels.size.height];
}
static NSString *ScreenSize(NSString *machine) {
    NSString *inches=ProfileField(machine,4);
    if (![inches length] || [inches isEqualToString:@"Unknown"]) return @"Unavailable";
    return [NSString stringWithFormat:@"%@ inches",inches];
}
static NSString *ScreenDensity(NSString *machine) {
    double inches=[[ProfileField(machine,4) description] doubleValue];
    if (inches<=0.0) return @"Unavailable";
    UIScreen *screen=[UIScreen mainScreen]; CGRect pixels=screen.bounds;
    if ([screen respondsToSelector:@selector(nativeBounds)]) pixels=screen.nativeBounds;
    else if ([screen respondsToSelector:@selector(scale)]) { pixels.size.width*=screen.scale; pixels.size.height*=screen.scale; }
    double diagonal=sqrt(pixels.size.width*pixels.size.width+pixels.size.height*pixels.size.height);
    return [NSString stringWithFormat:@"%.0f ppi",diagonal/inches];
}
static NSString *MemoryDescription(void) {
    uint64_t bytes = 0; size_t size = sizeof(bytes);
    if (sysctlbyname("hw.memsize", &bytes, &size, NULL, 0) != 0 || !bytes) return @"Unavailable";
    return [NSString stringWithFormat:@"%llu MB", (unsigned long long)(bytes / (1024 * 1024))];
}
static unsigned int ProcessorCount(void) {
    unsigned int count = 1; size_t size = sizeof(count); sysctlbyname("hw.ncpu", &count, &size, NULL, 0); return count ? count : 1;
}
static NSString *SysctlString(const char *name) {
    size_t size=0; if (sysctlbyname(name,NULL,&size,NULL,0)!=0 || !size) return @"Unavailable";
    char *value=malloc(size); if (!value) return @"Unavailable";
    if (sysctlbyname(name,value,&size,NULL,0)!=0) { free(value); return @"Unavailable"; }
    NSString *result=[NSString stringWithUTF8String:value]; free(value); return result ? result : @"Unavailable";
}
static NSString *CacheSize(const char *name) {
    uint64_t bytes=0; size_t size=sizeof(bytes);
    if (sysctlbyname(name,&bytes,&size,NULL,0)!=0 || !bytes) return @"Not reported by kernel";
    if (bytes >= 1024ULL*1024ULL) return [NSString stringWithFormat:@"%llu MB",(unsigned long long)(bytes/(1024ULL*1024ULL))];
    return [NSString stringWithFormat:@"%llu KB",(unsigned long long)(bytes/1024ULL)];
}
static NSString *StorageDescription(BOOL freeSpace) {
    NSDictionary *values=[[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/var" error:nil];
    NSNumber *bytes=[values objectForKey:(freeSpace?NSFileSystemFreeSize:NSFileSystemSize)];
    if (![bytes respondsToSelector:@selector(unsignedLongLongValue)] || ![bytes unsignedLongLongValue]) return @"Unavailable";
    return [NSString stringWithFormat:@"%llu MB",(unsigned long long)([bytes unsignedLongLongValue]/(1024ULL*1024ULL))];
}
static NSString *OpenGLESDescription(void) {
    EAGLContext *context=[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    if (!context || ![EAGLContext setCurrentContext:context]) { [context release]; return @"Unavailable"; }
    const GLubyte *vendor=glGetString(GL_VENDOR), *renderer=glGetString(GL_RENDERER), *version=glGetString(GL_VERSION);
    NSString *result=(renderer? [NSString stringWithUTF8String:(const char *)renderer] : @"Unavailable");
    if (vendor && version) result=[NSString stringWithFormat:@"%@ · %@ · ES %@",result,[NSString stringWithUTF8String:(const char *)vendor],[NSString stringWithUTF8String:(const char *)version]];
    [EAGLContext setCurrentContext:nil]; [context release]; return result;
}
static NSString *LiveFrequency(void) {
    uint64_t hz=0; size_t size=sizeof(hz);
    if (sysctlbyname("hw.cpufrequency",&hz,&size,NULL,0)!=0 || !hz) return @"Not reported by kernel";
    if (hz>=1000000000ULL) return [NSString stringWithFormat:@"%.2f GHz",(double)hz/1000000000.0];
    return [NSString stringWithFormat:@"%u MHz",(unsigned int)(hz/1000000ULL)];
}
static NSString *FreeMemoryDescription(void) {
    vm_statistics_data_t stats; mach_msg_type_number_t count=HOST_VM_INFO_COUNT;
    host_t host=mach_host_self(); kern_return_t result=host_statistics(host,HOST_VM_INFO,(host_info_t)&stats,&count); mach_port_deallocate(mach_task_self(),host);
    if (result!=KERN_SUCCESS) return @"Unavailable";
    uint64_t bytes=((uint64_t)stats.free_count+(uint64_t)stats.inactive_count)*(uint64_t)vm_page_size;
    uint64_t total=0; size_t size=sizeof(total); sysctlbyname("hw.memsize",&total,&size,NULL,0);
    unsigned int percent=total?(unsigned int)((bytes*100ULL)/total):0;
    return [NSString stringWithFormat:@"%llu MB (%u%%)",(unsigned long long)(bytes/(1024ULL*1024ULL)),percent];
}
static NSString *AppMemoryDescription(void) {
    task_basic_info_data_t info; mach_msg_type_number_t count=TASK_BASIC_INFO_COUNT;
    if (task_info(mach_task_self(),TASK_BASIC_INFO,(task_info_t)&info,&count)!=KERN_SUCCESS) return @"Unavailable";
    return [NSString stringWithFormat:@"%llu MB",(unsigned long long)(info.resident_size/(1024ULL*1024ULL))];
}
static NSString *CPUUsageDescription(void) {
    natural_t cpus=0; processor_info_array_t info=NULL; mach_msg_type_number_t count=0;
    host_t host=mach_host_self(); kern_return_t result=host_processor_info(host,PROCESSOR_CPU_LOAD_INFO,&cpus,&info,&count); mach_port_deallocate(mach_task_self(),host);
    if (result!=KERN_SUCCESS) return @"Unavailable";
    static uint64_t previousTotal=0, previousIdle=0; uint64_t total=0,idle=0;
    processor_cpu_load_info_t loads=(processor_cpu_load_info_t)info;
    for (natural_t i=0;i<cpus;i++) for (int state=0;state<CPU_STATE_MAX;state++) { uint64_t ticks=loads[i].cpu_ticks[state]; total+=ticks; if (state==CPU_STATE_IDLE) idle+=ticks; }
    NSString *value=@"Sampling…";
    if (previousTotal && total>previousTotal) { uint64_t dt=total-previousTotal, di=idle-previousIdle; value=[NSString stringWithFormat:@"%llu%%",(unsigned long long)(((dt-di)*100)/dt)]; }
    previousTotal=total; previousIdle=idle;
    vm_deallocate(mach_task_self(),(vm_address_t)info,(vm_size_t)(count*sizeof(integer_t)));
    return value;
}
static NSArray *PerCoreLoads(void) {
    natural_t cpus=0; processor_info_array_t info=NULL; mach_msg_type_number_t count=0;
    host_t host=mach_host_self(); kern_return_t result=host_processor_info(host,PROCESSOR_CPU_LOAD_INFO,&cpus,&info,&count); mach_port_deallocate(mach_task_self(),host);
    if (result!=KERN_SUCCESS) return [NSArray array];
    static uint64_t previous[64][2]; static BOOL hasPrevious=NO;
    NSMutableArray *values=[NSMutableArray array]; processor_cpu_load_info_t loads=(processor_cpu_load_info_t)info;
    for (natural_t i=0;i<cpus;i++) {
        uint64_t total=0,idle=0; for (int state=0;state<CPU_STATE_MAX;state++) { uint64_t ticks=loads[i].cpu_ticks[state]; total+=ticks; if(state==CPU_STATE_IDLE) idle+=ticks; }
        NSString *value=@"Sampling…";
        if (hasPrevious && i<64 && total>previous[i][0]) { uint64_t dt=total-previous[i][0], di=idle-previous[i][1]; value=[NSString stringWithFormat:@"%llu%%",(unsigned long long)(((dt-di)*100)/dt)]; }
        if(i<64) { previous[i][0]=total; previous[i][1]=idle; }
        [values addObject:value];
    }
    hasPrevious=YES; vm_deallocate(mach_task_self(),(vm_address_t)info,(vm_size_t)(count*sizeof(integer_t))); return values;
}
static NSArray *SoCSpecifications(NSString *soc) {
    NSDictionary *specs=[NSDictionary dictionaryWithObjectsAndKeys:
        [NSArray arrayWithObjects:@"ARMv6",@"ARM1176JZF-S",@"PowerVR MBX Lite",@"90 nm",@"1",nil],@"Samsung S5L8900",
        [NSArray arrayWithObjects:@"ARMv6",@"ARM1176JZF-S",@"PowerVR MBX Lite",@"65 nm",@"1",nil],@"Samsung S5L8720",
        [NSArray arrayWithObjects:@"ARMv7-A",@"ARM Cortex-A8",@"PowerVR SGX535",@"45 nm",@"1",nil],@"Apple A4",
        [NSArray arrayWithObjects:@"ARMv7-A",@"ARM Cortex-A9",@"PowerVR SGX543MP2",@"45 nm (32 nm revision)",@"2",nil],@"Apple A5",
        [NSArray arrayWithObjects:@"ARMv7-A",@"ARM Cortex-A9",@"PowerVR SGX543MP4",@"45 nm",@"2",nil],@"Apple A5X",
        [NSArray arrayWithObjects:@"ARMv7s",@"Apple Swift",@"PowerVR SGX543MP3",@"32 nm",@"2",nil],@"Apple A6",
        [NSArray arrayWithObjects:@"ARMv7s",@"Apple Swift",@"PowerVR SGX554MP4",@"32 nm",@"2",nil],@"Apple A6X",
        [NSArray arrayWithObjects:@"ARMv8-A",@"Apple Typhoon",@"PowerVR GX6450",@"20 nm",@"2",nil],@"Apple A8",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed dual-core CPU",@"PowerVR G6430",@"28 nm",@"2",nil],@"Apple A7",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed dual-core CPU",@"PowerVR GT7600",@"16/14 nm (vendor variant)",@"2",nil],@"Apple A9",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 2 efficiency)",@"Apple 6-core GPU",@"16 nm",@"4",nil],@"Apple A10 Fusion",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple 3-core GPU",@"10 nm",@"6",nil],@"Apple A11 Bionic",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple 4-core GPU",@"7 nm",@"6",nil],@"Apple A12 Bionic",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple 4-core GPU",@"7 nm+",@"6",nil],@"Apple A13 Bionic",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple 4-core GPU",@"5 nm",@"6",nil],@"Apple A14 Bionic",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple GPU (4 or 5 cores by model)",@"5 nm",@"6",nil],@"Apple A15 Bionic",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple 5-core GPU",@"4 nm",@"6",nil],@"Apple A16 Bionic",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (2 performance + 4 efficiency)",@"Apple 6-core GPU",@"3 nm",@"6",nil],@"Apple A17 Pro",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (4 performance + 4 efficiency)",@"Apple 8-core GPU",@"5 nm",@"8",nil],@"Apple M1",
        [NSArray arrayWithObjects:@"ARM64",@"Apple-designed (4 performance + 4 efficiency)",@"Apple 10-core GPU",@"5 nm (2nd generation)",@"8",nil],@"Apple M2",
        [NSArray arrayWithObjects:@"ARMv7-A",@"ARM Cortex-A8",@"PowerVR SGX535",@"65 nm",@"1",nil],@"Samsung S5PC100",
        [NSArray arrayWithObjects:@"ARMv7-A",@"ARM Cortex-A8",@"PowerVR SGX535",@"45 nm",@"1",nil],@"Samsung S5L8922",nil];
    return [specs objectForKey:soc];
}
static NSString *SoCField(NSString *soc, NSUInteger index) {
    NSArray *spec=SoCSpecifications(soc); return (spec && spec.count>index)?[spec objectAtIndex:index]:@"Unknown";
}
static NSString *ProcessNode(NSString *machine, NSString *soc) {
    if ([soc isEqualToString:@"Apple A5"] && ([machine isEqualToString:@"iPod5,1"] || [machine hasPrefix:@"iPad2,5"] || [machine hasPrefix:@"iPad2,6"] || [machine hasPrefix:@"iPad2,7"] || [machine isEqualToString:@"iPad2,4"])) return @"32 nm revision";
    return SoCField(soc,3);
}
static NSString *SupportedOSRange(NSString *machine) {
    NSDictionary *ranges=[NSDictionary dictionaryWithObjectsAndKeys:
        @"iPhone OS 1.0–3.1.3",@"iPhone1,1", @"iPhone OS 2.0–4.2.1",@"iPhone1,2", @"iPhone OS 3.1–6.1.6",@"iPod1,1", @"iPhone OS 2.1–4.2.1",@"iPod2,1",
        @"iOS 3.0–6.1.6",@"iPhone2,1", @"iOS 4.0–7.1.2",@"iPhone3,1", @"iOS 4.0–7.1.2",@"iPhone3,2", @"iOS 4.0–7.1.2",@"iPhone3,3", @"iOS 5.0–9.3.6",@"iPhone4,1", @"iOS 6.0–10.3.4",@"iPhone5,1", @"iOS 6.0–10.3.4",@"iPhone5,2",
        @"iOS 3.1–5.1.1",@"iPod3,1", @"iOS 4.1–6.1.6",@"iPod4,1", @"iOS 6.0–9.3.5",@"iPod5,1",
        @"iOS 8.0–12.5.x",@"iPhone7,1", @"iOS 8.0–12.5.x",@"iPhone7,2",
        @"iOS 7.0–12.5.x",@"iPhone6,1", @"iOS 7.0–12.5.x",@"iPhone6,2",
        @"iOS 9.0–15.x",@"iPhone8,1", @"iOS 9.0–15.x",@"iPhone8,2", @"iOS 9.3–15.x",@"iPhone8,4",
        @"iOS 10.0–15.x",@"iPhone9,1", @"iOS 10.0–15.x",@"iPhone9,2", @"iOS 10.0–15.x",@"iPhone9,3", @"iOS 10.0–15.x",@"iPhone9,4",
        @"iOS 11.0–16.x",@"iPhone10,1", @"iOS 11.0–16.x",@"iPhone10,2", @"iOS 11.0–16.x",@"iPhone10,3", @"iOS 11.0–16.x",@"iPhone10,4", @"iOS 11.0–16.x",@"iPhone10,5", @"iOS 11.0–16.x",@"iPhone10,6",
        @"iOS 12.0–18.x",@"iPhone11,2", @"iOS 12.0–18.x",@"iPhone11,4", @"iOS 12.0–18.x",@"iPhone11,6", @"iOS 12.0–18.x",@"iPhone11,8",
        @"iOS 13.0–26.x",@"iPhone12,1", @"iOS 13.0–26.x",@"iPhone12,3", @"iOS 13.0–26.x",@"iPhone12,5",
        @"iOS 14.0–26.x",@"iPhone13,1", @"iOS 14.0–26.x",@"iPhone13,2", @"iOS 14.0–26.x",@"iPhone13,3", @"iOS 14.0–26.x",@"iPhone13,4",
        @"iOS 15.0–26.x",@"iPhone14,2", @"iOS 15.0–26.x",@"iPhone14,3", @"iOS 15.0–26.x",@"iPhone14,4", @"iOS 15.0–26.x",@"iPhone14,5",
        @"iOS 16.0–26.x",@"iPhone14,7", @"iOS 16.0–26.x",@"iPhone14,8", @"iOS 16.0–26.x",@"iPhone15,2", @"iOS 16.0–26.x",@"iPhone15,3",
        @"iOS 17.0–26.x",@"iPhone15,4", @"iOS 17.0–26.x",@"iPhone15,5", @"iOS 17.0–26.x",@"iPhone16,1", @"iOS 17.0–26.x",@"iPhone16,2",
        @"iOS 3.2–5.1.1",@"iPad1,1", @"iOS 4.3–9.3.5",@"iPad2,1", @"iOS 4.3–9.3.5",@"iPad2,2", @"iOS 4.3–9.3.5",@"iPad2,3", @"iOS 5.0–9.3.5",@"iPad2,4", @"iOS 5.1–9.3.5",@"iPad3,1", @"iOS 5.1–9.3.5",@"iPad3,2", @"iOS 5.1–9.3.5",@"iPad3,3", @"iOS 6.0–10.3.4",@"iPad3,4", @"iOS 6.0–10.3.4",@"iPad3,5", @"iOS 6.0–10.3.4",@"iPad3,6", @"iOS 6.0–9.3.5",@"iPad2,5", @"iOS 6.0–9.3.5",@"iPad2,6", @"iOS 6.0–9.3.5",@"iPad2,7",
        @"iPadOS 14.5+",@"iPad13,4", @"iPadOS 14.5+",@"iPad13,5", @"iPadOS 14.5+",@"iPad13,6", @"iPadOS 14.5+",@"iPad13,7", @"iPadOS 14.5+",@"iPad13,8", @"iPadOS 14.5+",@"iPad13,9", @"iPadOS 14.5+",@"iPad13,10", @"iPadOS 14.5+",@"iPad13,11", @"iPadOS 14.5+",@"iPad13,16", @"iPadOS 14.5+",@"iPad13,17",
        @"iPadOS 16.1+",@"iPad14,3", @"iPadOS 16.1+",@"iPad14,4", @"iPadOS 16.1+",@"iPad14,5", @"iPadOS 16.1+",@"iPad14,6", @"iPadOS 17.5+",@"iPad14,8", @"iPadOS 17.5+",@"iPad14,9", @"iPadOS 17.5+",@"iPad14,10", @"iPadOS 17.5+",@"iPad14,11",nil];
    return [ranges objectForKey:machine] ? [ranges objectForKey:machine] : @"Unknown";
}
static NSString *BatteryDescription(void) {
    UIDevice *device = [UIDevice currentDevice]; NSString *state = @"Unknown state";
    if (device.batteryState == UIDeviceBatteryStateUnplugged) state = @"On battery";
    else if (device.batteryState == UIDeviceBatteryStateCharging) state = @"Charging";
    else if (device.batteryState == UIDeviceBatteryStateFull) state = @"Fully charged";
    if (device.batteryLevel >= 0.0f) return [NSString stringWithFormat:@"%@ · %d%%", state, (int)(device.batteryLevel * 100.0f)];
    return state;
}
static NSString *ThermalDescription(void) {
    NSProcessInfo *process=[NSProcessInfo processInfo];
    if (@available(iOS 11.0, *)) {
        if (![process respondsToSelector:@selector(thermalState)]) return @"Unavailable";
        switch (process.thermalState) {
            case NSProcessInfoThermalStateNominal: return @"Nominal";
            case NSProcessInfoThermalStateFair: return @"Fair";
            case NSProcessInfoThermalStateSerious: return @"Serious";
            case NSProcessInfoThermalStateCritical: return @"Critical";
            default: return @"Unknown";
        }
    }
    return @"Not available on this iOS version";
}

static UIColor *ThemeColor(NSInteger theme, NSInteger role) {
    /* Theme roles: bar, accent, page, panel, heading, key, value, separator. */
    static const unsigned int colors[6][8] = {
        {0x214F89,0x214F89,0xE6E8ED,0xFFFFFF,0x1F376F,0x111111,0x334A8A,0xCCCCCC},
        {0x151B22,0x55C7F2,0x101419,0x1B222B,0xF2F5F8,0xE6EAF0,0x7AD9FF,0x39434E},
        {0x111111,0x7C4DFF,0x101010,0x141414,0xD4C1F0,0xF2F2F2,0xB895D6,0x303030},
        {0x503777,0x503777,0xE6E8ED,0xFFFFFF,0x3B285A,0x111111,0x51427E,0xCCCCCC},
        {0x286447,0x286447,0xE6E8ED,0xFFFFFF,0x204F36,0x111111,0x315A42,0xCCCCCC},
        {0x963D49,0x963D49,0xE6E8ED,0xFFFFFF,0x702D36,0x111111,0x8A3541,0xCCCCCC}
    };
    if (theme < 0 || theme > 5) theme = 0;
    unsigned int rgb = colors[theme][role];
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0f
                           green:((rgb >> 8) & 0xFF) / 255.0f
                            blue:(rgb & 0xFF) / 255.0f alpha:1.0f];
}
static UIImage *TabIcon(NSInteger kind, UIColor *iconColor) {
    CGSize size = CGSizeMake(30, 30); UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef c = UIGraphicsGetCurrentContext(); CGContextSetStrokeColorWithColor(c, iconColor.CGColor);
    CGContextSetFillColorWithColor(c, iconColor.CGColor); CGContextSetLineWidth(c, 2.0f);
    if (kind == 0) { // overview: small device
        CGRect r = CGRectMake(7, 3, 16, 24); CGContextStrokeRect(c, r); CGContextFillEllipseInRect(c, CGRectMake(13, 23, 4, 2)); CGContextMoveToPoint(c, 10, 7); CGContextAddLineToPoint(c, 20, 7); CGContextStrokePath(c);
    } else if (kind == 1) { // processor: chip pins
        CGContextStrokeRect(c, CGRectMake(8, 8, 14, 14)); for (int i=0;i<4;i++) { CGFloat p=10+i*3.3f; CGContextMoveToPoint(c,p,4); CGContextAddLineToPoint(c,p,8); CGContextMoveToPoint(c,p,22); CGContextAddLineToPoint(c,p,26); CGContextMoveToPoint(c,4,p+1); CGContextAddLineToPoint(c,8,p+1); CGContextMoveToPoint(c,22,p+1); CGContextAddLineToPoint(c,26,p+1); } CGContextStrokePath(c);
    } else if (kind == 2) { // memory: three modules
        for (int i=0;i<3;i++) { CGRect r=CGRectMake(5+i*7,7,6,16); CGContextStrokeRect(c,r); CGContextMoveToPoint(c,7+i*7,23); CGContextAddLineToPoint(c,7+i*7,27); CGContextMoveToPoint(c,10+i*7,23); CGContextAddLineToPoint(c,10+i*7,27); } CGContextStrokePath(c);
    } else if (kind == 4) { // sensors: three-axis accelerometer
        CGContextStrokeEllipseInRect(c, CGRectMake(8,8,14,14));
        CGContextMoveToPoint(c,15,15); CGContextAddLineToPoint(c,25,7); CGContextMoveToPoint(c,15,15); CGContextAddLineToPoint(c,5,7); CGContextMoveToPoint(c,15,15); CGContextAddLineToPoint(c,15,27); CGContextStrokePath(c);
    } else { // system: gear-like sun
        CGContextStrokeEllipseInRect(c, CGRectMake(8,8,14,14)); CGContextStrokeEllipseInRect(c, CGRectMake(13,13,4,4)); for(int i=0;i<8;i++){CGFloat a=i*0.785398f; CGContextMoveToPoint(c,15+8*cosf(a),15+8*sinf(a)); CGContextAddLineToPoint(c,15+12*cosf(a),15+12*sinf(a));} CGContextStrokePath(c);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return image;
}

@interface InfoController : UIViewController <UIActionSheetDelegate> { NSString *_section; UISegmentedControl *_segments; UIScrollView *_cpuZTabs; UIScrollView *_scroll; NSTimer *_refreshTimer; NSTimer *_sensorTimer; NSMutableArray *_cpuValueLabels; UILabel *_cpuOverallValueLabel; UILabel *_accelValueLabel; UILabel *_batteryValueLabel; UILabel *_thermalValueLabel; CMMotionManager *_motionManager; }
- (id)initWithSection:(NSString *)section;
- (void)applyTheme;
- (void)buildSection;
- (void)updateCPUZTabs;
- (void)startAccelerometer;
- (void)stopAccelerometer;
- (void)updateAccelerometerReading;
@end
@implementation InfoController
- (id)initWithSection:(NSString *)section { if ((self=[super init])) _section=[section copy]; return self; }
- (void)dealloc { [self stopAccelerometer]; [_motionManager release]; [_section release]; [_segments release]; [_cpuZTabs release]; [_refreshTimer invalidate]; [_refreshTimer release]; [_cpuValueLabels release]; [super dealloc]; }
- (NSInteger)selectedTheme { NSInteger theme=[[NSUserDefaults standardUserDefaults] integerForKey:@"SoCGeniusTheme"]; return (theme >= 0 && theme <= 5) ? theme : 0; }
- (UIColor *)themeColorForRole:(NSInteger)role { return ThemeColor([self selectedTheme],role); }
- (void)applyTheme {
    self.view.backgroundColor=[self themeColorForRole:2];
    _segments.tintColor=[self themeColorForRole:1];
    _segments.hidden=([self selectedTheme]==2);
    _cpuZTabs.hidden=([self selectedTheme]!=2);
    _cpuZTabs.backgroundColor=[self themeColorForRole:0];
    if (self.navigationController) {
        UINavigationBar *bar=self.navigationController.navigationBar;
        UIColor *headerText=[UIColor colorWithWhite:0.98f alpha:1.0f];
        UIColor *headerBar=[self themeColorForRole:0];
        bar.barTintColor=headerBar; bar.tintColor=headerText; bar.translucent=NO;
        bar.titleTextAttributes=[NSDictionary dictionaryWithObjectsAndKeys:headerText,NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:17.0f],NSFontAttributeName,nil];
    }
    UIButton *themeButton=(UIButton *)self.navigationItem.rightBarButtonItem.customView;
    if (themeButton) {
        themeButton.backgroundColor=[UIColor colorWithWhite:0.0f alpha:0.24f];
        themeButton.layer.cornerRadius=6.0f; themeButton.layer.borderWidth=1.0f;
        themeButton.layer.borderColor=[UIColor colorWithWhite:1.0f alpha:0.78f].CGColor;
        [themeButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
    }
    [self updateCPUZTabs];
}
- (void)showThemePicker {
    NSArray *names=[NSArray arrayWithObjects:@"Blue",@"Dark",@"CPU-Z Classic",@"Purple",@"Green",@"Red",nil];
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *picker=[UIAlertController alertControllerWithTitle:@"Choose an appearance" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSString *name in names) {
            [picker addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSUInteger index=[names indexOfObject:action.title];
                [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"SoCGeniusTheme"];
                [self applyTheme]; [self buildSection];
            }]];
        }
        [picker addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        UIPopoverPresentationController *popover=picker.popoverPresentationController;
        if (popover) popover.barButtonItem=self.navigationItem.rightBarButtonItem;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"Choose an appearance" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Blue",@"Dark",@"CPU-Z Classic",@"Purple",@"Green",@"Red",nil];
        [sheet showInView:self.view]; [sheet release];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex < 0 || buttonIndex > 5) return;
    [[NSUserDefaults standardUserDefaults] setInteger:buttonIndex forKey:@"SoCGeniusTheme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self applyTheme]; [self buildSection];
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"SoC Genius 64";
    NSArray *sections=[NSArray arrayWithObjects:@"CPU",@"Device",@"Memory",@"Sensors",@"System",nil];
    _segments=[[UISegmentedControl alloc] initWithItems:sections]; _segments.frame=CGRectMake(10,5,self.view.bounds.size.width-20,32); _segments.autoresizingMask=UIViewAutoresizingFlexibleWidth; _segments.selectedSegmentIndex=0; [_segments addTarget:self action:@selector(sectionChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:_segments];
    _cpuZTabs=[[UIScrollView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,36)]; _cpuZTabs.backgroundColor=[self themeColorForRole:0]; _cpuZTabs.autoresizingMask=UIViewAutoresizingFlexibleWidth; _cpuZTabs.showsHorizontalScrollIndicator=NO; [self.view addSubview:_cpuZTabs];
    NSArray *cpuZLabels=[NSArray arrayWithObjects:@"SOC",@"DEVICE",@"MEMORY",@"SENSORS",@"SYSTEM",nil];
    CGFloat tabWidth=82.0f; _cpuZTabs.contentSize=CGSizeMake(MAX(self.view.bounds.size.width,tabWidth*[cpuZLabels count]),36);
    for (NSUInteger i=0;i<[cpuZLabels count];i++) {
        UIButton *tab=[UIButton buttonWithType:UIButtonTypeCustom]; tab.frame=CGRectMake(i*tabWidth,0,tabWidth,36); tab.tag=i; tab.titleLabel.font=[UIFont boldSystemFontOfSize:11]; [tab setTitle:[cpuZLabels objectAtIndex:i] forState:UIControlStateNormal]; [tab setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal]; [tab addTarget:self action:@selector(cpuZTabPressed:) forControlEvents:UIControlEventTouchUpInside];
        UIView *underline=[[[UIView alloc] initWithFrame:CGRectMake(0,33,tabWidth,3)] autorelease]; underline.tag=101; underline.backgroundColor=[self themeColorForRole:1]; [tab addSubview:underline]; [_cpuZTabs addSubview:tab];
    }
    UIButton *themeButton=[UIButton buttonWithType:UIButtonTypeCustom];
    themeButton.frame=CGRectMake(0,0,68,30); themeButton.titleLabel.font=[UIFont boldSystemFontOfSize:13.0f];
    [themeButton setTitle:@"Theme" forState:UIControlStateNormal];
    themeButton.accessibilityLabel=@"Change theme"; themeButton.accessibilityHint=@"Choose the app appearance";
    [themeButton addTarget:self action:@selector(showThemePicker) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem=[[[UIBarButtonItem alloc] initWithCustomView:themeButton] autorelease];
    [self applyTheme];
    [self buildSection];
}
- (void)updateCPUZTabs {
    for (UIView *view in _cpuZTabs.subviews) {
        if (![view isKindOfClass:[UIButton class]]) continue;
        UIButton *tab=(UIButton *)view; BOOL selected=(tab.tag==(NSUInteger)_segments.selectedSegmentIndex);
        [tab setTitleColor:(selected?[self themeColorForRole:4]:[UIColor colorWithRed:0.78f green:0.78f blue:0.78f alpha:1]) forState:UIControlStateNormal];
        UIView *underline=[tab viewWithTag:101]; underline.backgroundColor=[self themeColorForRole:1]; underline.hidden=!selected;
    }
}
- (void)cpuZTabPressed:(UIButton *)sender {
    _segments.selectedSegmentIndex=sender.tag; [self sectionChanged:_segments]; [self updateCPUZTabs];
    CGFloat left=sender.frame.origin.x, right=left+sender.frame.size.width;
    CGFloat visibleLeft=_cpuZTabs.contentOffset.x, visibleRight=visibleLeft+_cpuZTabs.bounds.size.width;
    if (left<visibleLeft) [_cpuZTabs setContentOffset:CGPointMake(left,0) animated:YES];
    else if (right>visibleRight) [_cpuZTabs setContentOffset:CGPointMake(right-_cpuZTabs.bounds.size.width,0) animated:YES];
}
- (void)startAccelerometer {
    if (!_motionManager) _motionManager=[[CMMotionManager alloc] init];
    if (![_motionManager isAccelerometerAvailable]) { if (_accelValueLabel) _accelValueLabel.text=@"Unavailable"; return; }
    _motionManager.accelerometerUpdateInterval=0.2;
    [_motionManager startAccelerometerUpdates];
    [_sensorTimer invalidate]; [_sensorTimer release];
    _sensorTimer=[[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateAccelerometerReading) userInfo:nil repeats:YES] retain];
}
- (void)stopAccelerometer {
    [_sensorTimer invalidate]; [_sensorTimer release]; _sensorTimer=nil;
    [_motionManager stopAccelerometerUpdates];
}
- (void)updateAccelerometerReading {
    CMAccelerometerData *data=_motionManager.accelerometerData;
    if (!data || !_accelValueLabel) return;
    CMAcceleration reading=data.acceleration;
    _accelValueLabel.text=[NSString stringWithFormat:@"X %.2f   Y %.2f   Z %.2f",reading.x,reading.y,reading.z];
}
- (void)sectionChanged:(id)sender {
    NSArray *values=[NSArray arrayWithObjects:@"Processor",@"iDevice Info",@"Memory",@"Sensors",@"System",nil];
    [self stopAccelerometer];
    [_section release]; _section=[[values objectAtIndex:_segments.selectedSegmentIndex] copy]; [self buildSection];
    if ([_section isEqualToString:@"Sensors"]) [self startAccelerometer];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_refreshTimer) _refreshTimer=[[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshReadings) userInfo:nil repeats:YES] retain];
    if ([_section isEqualToString:@"Sensors"]) [self startAccelerometer];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated]; [_refreshTimer invalidate]; [_refreshTimer release]; _refreshTimer=nil;
    [self stopAccelerometer];
}
- (void)refreshReadings {
    if (_batteryValueLabel) _batteryValueLabel.text=BatteryDescription();
    if (_thermalValueLabel) _thermalValueLabel.text=ThermalDescription();
    if ([_section isEqualToString:@"Processor"]) {
        if (_cpuOverallValueLabel) _cpuOverallValueLabel.text=CPUUsageDescription();
        NSArray *loads=PerCoreLoads();
        for (NSUInteger i=0;i<[_cpuValueLabels count] && i<[loads count];i++) [[_cpuValueLabels objectAtIndex:i] setText:[loads objectAtIndex:i]];
    }
}
- (void)buildSection {
    if (_scroll) { [_scroll removeFromSuperview]; [_scroll release]; _scroll=nil; }
    [_cpuValueLabels release]; _cpuValueLabels=[[NSMutableArray alloc] init]; _cpuOverallValueLabel=nil; _accelValueLabel=nil; _batteryValueLabel=nil; _thermalValueLabel=nil;
    CGFloat width=self.view.bounds.size.width; CGFloat top=([self selectedTheme]==2)?36:44;
    _scroll=[[UIScrollView alloc] initWithFrame:CGRectMake(0,top,width,self.view.bounds.size.height-top)]; _scroll.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; _scroll.backgroundColor=[self themeColorForRole:2]; [self.view addSubview:_scroll];
    UIScrollView *scroll=_scroll;
    NSString *machine=MachineIdentifier(); UIDevice *device=[UIDevice currentDevice]; NSMutableArray *rows=[NSMutableArray array];
    NSString *soc=ProfileField(machine,1);
    if ([_section isEqualToString:@"Processor"]) {
        [rows addObject:[NSArray arrayWithObjects:@"SoC",soc,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"CPU Cores",SoCField(soc,4),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Logical Cores",[NSString stringWithFormat:@"%u",ProcessorCount()],nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Architecture",SoCField(soc,0),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Microarchitecture",SoCField(soc,1),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"GPU Vendor",([SoCField(soc,2) hasPrefix:@"PowerVR"]?@"Imagination Technologies":([SoCField(soc,2) hasPrefix:@"Apple"]?@"Apple":@"Unknown")),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"GPU",SoCField(soc,2),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"GPU Renderer",OpenGLESDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Process",ProcessNode(machine,soc),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Maximum Clock (reported)",ProfileField(machine,2),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"CPU Load",CPUUsageDescription(),nil]];
        natural_t processorCount=ProcessorCount();
        for (natural_t core=0;core<processorCount;core++) [rows addObject:[NSArray arrayWithObjects:[NSString stringWithFormat:@"CPU %u Load",core],@"Sampling…",nil]];
        [rows addObject:[NSArray arrayWithObjects:@"L1 Instruction Cache",CacheSize("hw.l1icachesize"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"L1 Data Cache",CacheSize("hw.l1dcachesize"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"L2 Cache",CacheSize("hw.l2cachesize"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"L3 Cache",CacheSize("hw.l3cachesize"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Kernel Frequency",LiveFrequency(),nil]];
    } else if ([_section isEqualToString:@"iDevice Info"]) {
        [rows addObject:[NSArray arrayWithObjects:@"Marketing Name",DeviceProfile(machine)?ProfileField(machine,0):FriendlyModelName(machine),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Manufacturer",@"Apple",nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Device Family",device.model,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Hardware Identifier",machine,nil]];
        NSString *platformModel=SysctlString("hw.model");
        [rows addObject:[NSArray arrayWithObjects:@"Platform Model",[platformModel isEqualToString:machine]?@"Same as hardware identifier":platformModel,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Screen Size",ScreenSize(machine),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Installed RAM",MemoryDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Display Resolution",PixelResolution(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Screen Density",ScreenDensity(machine),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Current iOS",[NSString stringWithFormat:@"%@ (%@)",device.systemVersion,SysctlString("kern.osversion")],nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Stock iOS Range",SupportedOSRange(machine),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Battery",BatteryDescription(),nil]];
    } else if ([_section isEqualToString:@"Memory"]) {
        [rows addObject:[NSArray arrayWithObjects:@"Installed Memory",MemoryDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Available Memory",FreeMemoryDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"App Resident Memory",AppMemoryDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Storage Capacity",StorageDescription(NO),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Storage Available",StorageDescription(YES),nil]];
    } else if ([_section isEqualToString:@"Sensors"]) {
        [rows addObject:[NSArray arrayWithObjects:@"Accelerometer",@"Starting…",nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Update Rate",@"5 Hz",nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Availability",@"Device accelerometer",nil]];
    } else {
        NSDictionary *bundleInfo=[[NSBundle mainBundle] infoDictionary];
        NSString *appVersion=[bundleInfo objectForKey:@"CFBundleShortVersionString"];
        NSString *buildVersion=[bundleInfo objectForKey:@"CFBundleVersion"];
        [rows addObject:[NSArray arrayWithObjects:@"System",device.systemName,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"iOS Version",device.systemVersion,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"OS Build",SysctlString("kern.osversion"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Darwin Kernel",SysctlString("kern.osrelease"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Platform Model",SysctlString("hw.model"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Hardware Identifier",machine,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Thermal State",ThermalDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"App",@"SoC Genius 64",nil]];
        [rows addObject:[NSArray arrayWithObjects:@"App Version",[NSString stringWithFormat:@"%@ (%@)",appVersion?appVersion:@"Unknown",buildVersion?buildVersion:@"Unknown"],nil]];
    }
    BOOL cpuZStyle=([self selectedTheme]==2);
    CGFloat rowHeight=cpuZStyle?36.0f:44.0f;
    CGFloat y=cpuZStyle?0.0f:18.0f;
    if ([_section isEqualToString:@"Processor"]) {
        NSString *imageName=ProfileField(machine,3); UIImage *socImage=nil;
        if (![imageName isEqualToString:@""] && ![imageName isEqualToString:@"Unknown"]) socImage=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"]];
        UIView *banner=[[[UIView alloc] initWithFrame:CGRectMake(0,y,width,108)] autorelease]; banner.backgroundColor=[self themeColorForRole:3]; [scroll addSubview:banner];
        if (socImage) { UIImageView *photo=[[[UIImageView alloc] initWithImage:socImage] autorelease]; photo.contentMode=UIViewContentModeScaleAspectFit; photo.frame=cpuZStyle?CGRectMake(12,9,82,88):CGRectMake(width-112,9,90,88); photo.autoresizingMask=cpuZStyle?UIViewAutoresizingFlexibleRightMargin:UIViewAutoresizingFlexibleLeftMargin; [banner addSubview:photo]; }
        else { UIImageView *chipIcon=[[[UIImageView alloc] initWithImage:TabIcon(1,[self themeColorForRole:1])] autorelease]; chipIcon.frame=cpuZStyle?CGRectMake(27,39,48,48):CGRectMake(width-92,39,48,48); [banner addSubview:chipIcon]; }
        NSString *summary=[NSString stringWithFormat:@"%@\n%@ CPU cores",soc,SoCField(soc,4)];
        UILabel *chip=[[[UILabel alloc] initWithFrame:cpuZStyle?CGRectMake(104,y+26,width-116,60):CGRectMake(18,y+30,width-145,50)] autorelease]; chip.text=summary; chip.numberOfLines=2; chip.font=[UIFont boldSystemFontOfSize:18]; chip.textColor=[self themeColorForRole:4]; chip.backgroundColor=[UIColor clearColor]; chip.autoresizingMask=UIViewAutoresizingFlexibleWidth; [scroll addSubview:chip]; y+=118;
    } else if (![_section isEqualToString:@"Processor"] && !cpuZStyle) {
        NSInteger iconKind=[_section isEqualToString:@"iDevice Info"]?0:([_section isEqualToString:@"Memory"]?2:([_section isEqualToString:@"Sensors"]?4:3));
        UIImageView *icon=[[[UIImageView alloc] initWithImage:TabIcon(iconKind,[self themeColorForRole:1])] autorelease]; icon.frame=CGRectMake(16,y+8,30,30); [scroll addSubview:icon];
        UILabel *heading=[[[UILabel alloc] initWithFrame:CGRectMake(56,y,width-72,44)] autorelease]; heading.text=[_section uppercaseString]; heading.font=[UIFont boldSystemFontOfSize:16]; heading.textColor=[self themeColorForRole:4]; heading.backgroundColor=[UIColor clearColor]; heading.autoresizingMask=UIViewAutoresizingFlexibleWidth; [scroll addSubview:heading]; y+=50;
    }
    UIView *group=[[[UIView alloc] initWithFrame:CGRectMake(0,y,width,rows.count*rowHeight)] autorelease]; group.backgroundColor=[self themeColorForRole:3]; group.layer.cornerRadius=cpuZStyle?0.0f:8.0f; group.clipsToBounds=YES; group.autoresizingMask=UIViewAutoresizingFlexibleWidth; [scroll addSubview:group];
    for (NSUInteger i=0;i<rows.count;i++) {
        NSArray *row=[rows objectAtIndex:i]; CGFloat rowY=i*rowHeight;
        UILabel *key=[[[UILabel alloc] initWithFrame:CGRectMake(cpuZStyle?20:15,rowY,width*0.43f-(cpuZStyle?20:15),rowHeight)] autorelease]; key.text=[row objectAtIndex:0]; key.font=[UIFont systemFontOfSize:cpuZStyle?14:16]; key.textColor=[self themeColorForRole:5]; key.backgroundColor=[UIColor clearColor]; key.autoresizingMask=UIViewAutoresizingFlexibleWidth; [group addSubview:key];
        UILabel *value=[[[UILabel alloc] initWithFrame:CGRectMake(width*0.43f,rowY,width*0.57f-(cpuZStyle?18:28),rowHeight)] autorelease]; value.text=[row objectAtIndex:1]; value.font=[UIFont systemFontOfSize:cpuZStyle?14:16]; value.textColor=[self themeColorForRole:6]; value.textAlignment=cpuZStyle?NSTextAlignmentLeft:NSTextAlignmentRight; value.numberOfLines=2; value.adjustsFontSizeToFitWidth=YES; value.backgroundColor=[UIColor clearColor]; value.autoresizingMask=UIViewAutoresizingFlexibleWidth; [group addSubview:value];
        NSString *keyName=[row objectAtIndex:0];
        if ([keyName isEqualToString:@"CPU Load"]) _cpuOverallValueLabel=value;
        if (![keyName isEqualToString:@"CPU Load"] && [keyName hasPrefix:@"CPU "] && [keyName hasSuffix:@" Load"]) [_cpuValueLabels addObject:value];
        if ([keyName isEqualToString:@"Accelerometer"]) _accelValueLabel=value;
        if ([keyName isEqualToString:@"Battery"]) _batteryValueLabel=value;
        if ([keyName isEqualToString:@"Thermal State"]) _thermalValueLabel=value;
        if (i+1<rows.count) { UIView *line=[[[UIView alloc] initWithFrame:CGRectMake(cpuZStyle?0:15,rowY+rowHeight-0.5f,width-(cpuZStyle?0:15),0.5)] autorelease]; line.backgroundColor=[self themeColorForRole:7]; line.autoresizingMask=UIViewAutoresizingFlexibleWidth; [group addSubview:line]; }
    }
    scroll.contentSize=CGSizeMake(width,y+rows.count*rowHeight+(cpuZStyle?12:18));
}
@end

@interface AppDelegate : NSObject <UIApplicationDelegate> { UIWindow *_window; }
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    [UIDevice currentDevice].batteryMonitoringEnabled=YES; _window=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    InfoController *info=[[[InfoController alloc] initWithSection:@"Processor"] autorelease]; UINavigationController *nav=[[[UINavigationController alloc] initWithRootViewController:info] autorelease]; nav.navigationBar.tintColor=ThemeColor([[NSUserDefaults standardUserDefaults] integerForKey:@"SoCGeniusTheme"],0);
    if ([_window respondsToSelector:@selector(setRootViewController:)]) _window.rootViewController=nav; else [_window addSubview:nav.view];
    [_window makeKeyAndVisible]; return YES;
}
- (void)dealloc { [_window release]; [super dealloc]; }
@end
int main(int argc,char *argv[]) { NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; int result=UIApplicationMain(argc,argv,nil,NSStringFromClass([AppDelegate class])); [pool drain]; return result; }
