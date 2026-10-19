#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <math.h>
#import <mach/mach.h>
#import <mach/processor_info.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <sys/mount.h>

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
    NSDictionary *models = [NSDictionary dictionaryWithObjectsAndKeys:@"iPhone 5 (GSM)", @"iPhone5,1", @"iPhone 5 (CDMA)", @"iPhone5,2", nil];
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
        @"iPhone 5|Apple A6|1.3 GHz|Apple_A6_Chip", @"iPhone5,1", @"iPhone 5|Apple A6|1.3 GHz|Apple_A6_Chip", @"iPhone5,2",
        @"iPod touch (1st generation)|Samsung S5L8900|412 MHz|", @"iPod1,1",
        @"iPod touch (2nd generation)|Samsung S5L8720|533 MHz|", @"iPod2,1",
        @"iPod touch (3rd generation)|Samsung S5L8922|600 MHz|S5L8922", @"iPod3,1",
        @"iPod touch (4th generation)|Apple A4|800 MHz|Apple_A4_Chip", @"iPod4,1",
        @"iPod touch (5th generation)|Apple A5|800 MHz|Apple_A5_Chip", @"iPod5,1",
        @"iPad|Apple A4|1 GHz|Apple_A4_Chip", @"iPad1,1",
        @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,1", @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,2", @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,3", @"iPad 2|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,4",
        @"iPad (3rd generation)|Apple A5X|1 GHz|Apple_A5X_Chip", @"iPad3,1", @"iPad (3rd generation)|Apple A5X|1 GHz|Apple_A5X_Chip", @"iPad3,2", @"iPad (3rd generation)|Apple A5X|1 GHz|Apple_A5X_Chip", @"iPad3,3",
        @"iPad (4th generation)|Apple A6X|1.4 GHz|Apple_A6X_chip", @"iPad3,4", @"iPad (4th generation)|Apple A6X|1.4 GHz|Apple_A6X_chip", @"iPad3,5", @"iPad (4th generation)|Apple A6X|1.4 GHz|Apple_A6X_chip", @"iPad3,6",
        @"iPad mini|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,5", @"iPad mini|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,6", @"iPad mini|Apple A5|1 GHz|Apple_A5_Chip", @"iPad2,7", nil];
    return [profiles objectForKey:machine];
}
static NSString *ProfileField(NSString *machine, NSUInteger field) {
    NSArray *parts = [[DeviceProfile(machine) componentsSeparatedByString:@"|"] retain];
    NSString *value = (parts && parts.count > field) ? [parts objectAtIndex:field] : @"Unknown";
    NSString *result = [[value copy] autorelease]; [parts release]; return result;
}
static NSString *PixelResolution(void) {
    CGSize points = [[UIScreen mainScreen] bounds].size; CGFloat scale = 1.0f;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) scale=[[UIScreen mainScreen] scale];
    return [NSString stringWithFormat:@"%.0f × %.0f", points.width * scale, points.height * scale];
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
    uint64_t pages=(uint64_t)stats.free_count+(uint64_t)stats.inactive_count;
    return [NSString stringWithFormat:@"%llu MB",(unsigned long long)((pages*(uint64_t)vm_page_size)/(1024ULL*1024ULL))];
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
        @"iOS 3.2–5.1.1",@"iPad1,1", @"iOS 4.3–9.3.5",@"iPad2,1", @"iOS 4.3–9.3.5",@"iPad2,2", @"iOS 4.3–9.3.5",@"iPad2,3", @"iOS 5.0–9.3.5",@"iPad2,4", @"iOS 5.1–9.3.5",@"iPad3,1", @"iOS 5.1–9.3.5",@"iPad3,2", @"iOS 5.1–9.3.5",@"iPad3,3", @"iOS 6.0–10.3.4",@"iPad3,4", @"iOS 6.0–10.3.4",@"iPad3,5", @"iOS 6.0–10.3.4",@"iPad3,6", @"iOS 6.0–9.3.5",@"iPad2,5", @"iOS 6.0–9.3.5",@"iPad2,6", @"iOS 6.0–9.3.5",@"iPad2,7",nil];
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

static UIImage *TabIcon(NSInteger kind) {
    CGSize size = CGSizeMake(30, 30); UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    UIColor *blue=[UIColor colorWithRed:0.13 green:0.34 blue:0.65 alpha:1];
    CGContextRef c = UIGraphicsGetCurrentContext(); CGContextSetStrokeColorWithColor(c, blue.CGColor);
    CGContextSetFillColorWithColor(c, blue.CGColor); CGContextSetLineWidth(c, 2.0f);
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

@interface InfoController : UIViewController <UIAccelerometerDelegate> { NSString *_section; UISegmentedControl *_segments; UIScrollView *_scroll; NSTimer *_refreshTimer; NSMutableArray *_cpuValueLabels; UILabel *_cpuOverallValueLabel; UILabel *_accelValueLabel; UIAccelerometer *_accelerometer; }
- (id)initWithSection:(NSString *)section;
@end
@implementation InfoController
- (id)initWithSection:(NSString *)section { if ((self=[super init])) _section=[section copy]; return self; }
- (void)dealloc { if (_accelerometer) _accelerometer.delegate=nil; [_section release]; [_segments release]; [_refreshTimer invalidate]; [_refreshTimer release]; [_cpuValueLabels release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"SoC Genius";
    self.view.backgroundColor = [UIColor colorWithRed:0.90 green:0.91 blue:0.93 alpha:1.0];
    NSArray *sections=[NSArray arrayWithObjects:@"CPU",@"Device",@"Memory",@"Sensors",@"System",nil];
    _segments=[[UISegmentedControl alloc] initWithItems:sections]; _segments.frame=CGRectMake(10,5,self.view.bounds.size.width-20,32); _segments.autoresizingMask=UIViewAutoresizingFlexibleWidth; _segments.segmentedControlStyle=UISegmentedControlStyleBar; _segments.tintColor=[UIColor colorWithRed:0.13 green:0.34 blue:0.65 alpha:1]; _segments.selectedSegmentIndex=0; [_segments addTarget:self action:@selector(sectionChanged:) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:_segments];
    [self buildSection];
}
- (void)sectionChanged:(id)sender {
    NSArray *values=[NSArray arrayWithObjects:@"Processor",@"iDevice Info",@"Memory",@"Sensors",@"System",nil];
    if (_accelerometer) _accelerometer.delegate=nil;
    [_section release]; _section=[[values objectAtIndex:_segments.selectedSegmentIndex] copy]; [self buildSection];
    if ([_section isEqualToString:@"Sensors"]) { _accelerometer=[UIAccelerometer sharedAccelerometer]; _accelerometer.updateInterval=0.2; _accelerometer.delegate=self; }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_refreshTimer) _refreshTimer=[[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshReadings) userInfo:nil repeats:YES] retain];
    if ([_section isEqualToString:@"Sensors"]) { _accelerometer=[UIAccelerometer sharedAccelerometer]; _accelerometer.updateInterval=0.2; _accelerometer.delegate=self; }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated]; [_refreshTimer invalidate]; [_refreshTimer release]; _refreshTimer=nil;
    if (_accelerometer) _accelerometer.delegate=nil;
}
- (void)refreshReadings {
    if ([_section isEqualToString:@"Processor"]) {
        if (_cpuOverallValueLabel) _cpuOverallValueLabel.text=CPUUsageDescription();
        NSArray *loads=PerCoreLoads();
        for (NSUInteger i=0;i<[_cpuValueLabels count] && i<[loads count];i++) [[_cpuValueLabels objectAtIndex:i] setText:[loads objectAtIndex:i]];
    }
}
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)reading {
    if (_accelValueLabel) _accelValueLabel.text=[NSString stringWithFormat:@"X %.2f   Y %.2f   Z %.2f",reading.x,reading.y,reading.z];
}
- (void)buildSection {
    if (_scroll) { [_scroll removeFromSuperview]; [_scroll release]; _scroll=nil; }
    [_cpuValueLabels release]; _cpuValueLabels=[[NSMutableArray alloc] init]; _cpuOverallValueLabel=nil; _accelValueLabel=nil;
    CGFloat width=self.view.bounds.size.width; CGFloat top=44;
    _scroll=[[UIScrollView alloc] initWithFrame:CGRectMake(0,top,width,self.view.bounds.size.height-top)]; _scroll.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; [self.view addSubview:_scroll];
    UIScrollView *scroll=_scroll;
    NSString *machine=MachineIdentifier(); UIDevice *device=[UIDevice currentDevice]; NSMutableArray *rows=[NSMutableArray array];
    NSString *soc=ProfileField(machine,1);
    if ([_section isEqualToString:@"Processor"]) {
        [rows addObject:[NSArray arrayWithObjects:@"SoC",soc,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"CPU Cores",SoCField(soc,4),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Logical Cores",[NSString stringWithFormat:@"%u",ProcessorCount()],nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Architecture",SoCField(soc,0),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Microarchitecture",SoCField(soc,1),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"GPU",SoCField(soc,2),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"GPU Renderer",OpenGLESDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Process",ProcessNode(machine,soc),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Maximum Clock (spec)",ProfileField(machine,2),nil]];
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
        [rows addObject:[NSArray arrayWithObjects:@"Device Family",device.model,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Hardware Identifier",machine,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Board ID",SysctlString("hw.model"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Installed RAM",MemoryDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Display Resolution",PixelResolution(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Current iOS",[NSString stringWithFormat:@"%@ (%@)",device.systemVersion,SysctlString("kern.osversion")],nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Stock iOS Range",SupportedOSRange(machine),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Battery",BatteryDescription(),nil]];
    } else if ([_section isEqualToString:@"Memory"]) {
        [rows addObject:[NSArray arrayWithObjects:@"Installed Memory",MemoryDescription(),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Free + Inactive",FreeMemoryDescription(),nil]];
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
        [rows addObject:[NSArray arrayWithObjects:@"Board ID",SysctlString("hw.model"),nil]];
        [rows addObject:[NSArray arrayWithObjects:@"Hardware Identifier",machine,nil]];
        [rows addObject:[NSArray arrayWithObjects:@"App",@"SoC Genius",nil]];
        [rows addObject:[NSArray arrayWithObjects:@"App Version",[NSString stringWithFormat:@"%@ (%@)",appVersion?appVersion:@"Unknown",buildVersion?buildVersion:@"Unknown"],nil]];
    }
    CGFloat y=18;
    if ([_section isEqualToString:@"Processor"]) {
        NSString *imageName=ProfileField(machine,3); UIImage *soc=nil;
        if (![imageName isEqualToString:@""] && ![imageName isEqualToString:@"Unknown"]) soc=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"]];
        UIView *banner=[[[UIView alloc] initWithFrame:CGRectMake(0,y,width,108)] autorelease]; banner.backgroundColor=[UIColor whiteColor]; [scroll addSubview:banner];
        if (soc) { UIImageView *photo=[[[UIImageView alloc] initWithImage:soc] autorelease]; photo.contentMode=UIViewContentModeScaleAspectFit; photo.frame=CGRectMake(width-112,9,90,88); photo.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin; [banner addSubview:photo]; }
        UILabel *chip=[[[UILabel alloc] initWithFrame:CGRectMake(18,y+30,width-145,50)] autorelease]; chip.text=[NSString stringWithFormat:@"%@\n%@ nominal",ProfileField(machine,1),ProfileField(machine,2)]; chip.numberOfLines=2; chip.font=[UIFont boldSystemFontOfSize:18]; chip.textColor=[UIColor colorWithRed:0.12 green:0.21 blue:0.43 alpha:1]; chip.backgroundColor=[UIColor clearColor]; chip.autoresizingMask=UIViewAutoresizingFlexibleWidth; [scroll addSubview:chip]; y+=118;
    } else if (![_section isEqualToString:@"Processor"]) {
        NSInteger iconKind=[_section isEqualToString:@"iDevice Info"]?0:([_section isEqualToString:@"Memory"]?2:([_section isEqualToString:@"Sensors"]?4:3));
        UIImageView *icon=[[[UIImageView alloc] initWithImage:TabIcon(iconKind)] autorelease]; icon.frame=CGRectMake(16,y+8,30,30); [scroll addSubview:icon];
        UILabel *heading=[[[UILabel alloc] initWithFrame:CGRectMake(56,y,width-72,44)] autorelease]; heading.text=[_section uppercaseString]; heading.font=[UIFont boldSystemFontOfSize:16]; heading.textColor=[UIColor colorWithRed:0.12 green:0.21 blue:0.43 alpha:1]; heading.backgroundColor=[UIColor clearColor]; heading.autoresizingMask=UIViewAutoresizingFlexibleWidth; [scroll addSubview:heading]; y+=50;
    }
    UIView *group=[[[UIView alloc] initWithFrame:CGRectMake(0,y,width,rows.count*44)] autorelease]; group.backgroundColor=[UIColor whiteColor]; group.layer.cornerRadius=8.0f; group.clipsToBounds=YES; group.autoresizingMask=UIViewAutoresizingFlexibleWidth; [scroll addSubview:group];
    for (NSUInteger i=0;i<rows.count;i++) {
        NSArray *row=[rows objectAtIndex:i]; CGFloat rowY=i*44;
        UILabel *key=[[[UILabel alloc] initWithFrame:CGRectMake(15,rowY,width*0.43f-15,44)] autorelease]; key.text=[row objectAtIndex:0]; key.font=[UIFont systemFontOfSize:16]; key.textColor=[UIColor blackColor]; key.backgroundColor=[UIColor clearColor]; key.autoresizingMask=UIViewAutoresizingFlexibleWidth; [group addSubview:key];
        UILabel *value=[[[UILabel alloc] initWithFrame:CGRectMake(width*0.43f,rowY,width*0.57f-28,44)] autorelease]; value.text=[row objectAtIndex:1]; value.font=[UIFont systemFontOfSize:16]; value.textColor=[UIColor colorWithRed:0.20 green:0.29 blue:0.55 alpha:1]; value.textAlignment=NSTextAlignmentRight; value.numberOfLines=2; value.adjustsFontSizeToFitWidth=YES; value.backgroundColor=[UIColor clearColor]; value.autoresizingMask=UIViewAutoresizingFlexibleWidth; [group addSubview:value];
        NSString *keyName=[row objectAtIndex:0];
        if ([keyName isEqualToString:@"CPU Load"]) _cpuOverallValueLabel=value;
        if (![keyName isEqualToString:@"CPU Load"] && [keyName hasPrefix:@"CPU "] && [keyName hasSuffix:@" Load"]) [_cpuValueLabels addObject:value];
        if ([keyName isEqualToString:@"Accelerometer"]) _accelValueLabel=value;
        if (i+1<rows.count) { UIView *line=[[[UIView alloc] initWithFrame:CGRectMake(15,rowY+43,width-15,0.5)] autorelease]; line.backgroundColor=[UIColor colorWithWhite:0.80 alpha:1]; line.autoresizingMask=UIViewAutoresizingFlexibleWidth; [group addSubview:line]; }
    }
    scroll.contentSize=CGSizeMake(width,y+rows.count*44+18);
}
@end

@interface AppDelegate : NSObject <UIApplicationDelegate> { UIWindow *_window; }
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    [UIDevice currentDevice].batteryMonitoringEnabled=YES; _window=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    InfoController *info=[[[InfoController alloc] initWithSection:@"Processor"] autorelease]; UINavigationController *nav=[[[UINavigationController alloc] initWithRootViewController:info] autorelease]; nav.navigationBar.tintColor=[UIColor colorWithRed:0.13 green:0.34 blue:0.65 alpha:1];
    if ([_window respondsToSelector:@selector(setRootViewController:)]) _window.rootViewController=nav; else [_window addSubview:nav.view];
    [_window makeKeyAndVisible]; return YES;
}
- (void)dealloc { [_window release]; [super dealloc]; }
@end
int main(int argc,char *argv[]) { NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; int result=UIApplicationMain(argc,argv,nil,NSStringFromClass([AppDelegate class])); [pool drain]; return result; }
