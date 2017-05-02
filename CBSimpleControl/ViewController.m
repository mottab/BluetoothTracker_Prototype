//
//  ViewController.m
//  CBSimpleControl
//
//  Created by Mostafa Khattab on 4/30/17.
//  Copyright © 2017 Mostafa Khattab. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@property (nonatomic, strong) CBCentralManager *myCentralManager;
@property (nonatomic, strong) NSMutableArray *discoveredPeripheral;
@property (nonatomic, strong) CBPeripheral *myPeripheral;
@property (nonatomic, strong) CBCharacteristic * interestingCharacterisitic;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setup
{
    _discoveredPeripheral = [[NSMutableArray alloc] init];
    _myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    UIBarButtonItem *scanButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Scan"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(scanPeripherals:)];
    self.navigationItem.rightBarButtonItem = scanButton;
    
    UIBarButtonItem *sayHelloButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Say hello"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(HelloPeripheral:)];
    self.navigationItem.leftBarButtonItem = sayHelloButton;
    
    self.textView.text = @"---";
}

- (void) scanPeripherals:(id)btn
{
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    [_myCentralManager scanForPeripheralsWithServices:nil options:nil];
    [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Scanning\n"]];
}

- (void) HelloPeripheral:(id)btn
{
    NSLog(@"Writing value for characteristic %@", self.interestingCharacterisitic);
    [self.myPeripheral writeValue:[[NSString stringWithFormat:@"Hello"] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.interestingCharacterisitic
                      type:CBCharacteristicWriteWithResponse];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@", peripheral.name);
    [self.discoveredPeripheral addObject:peripheral];
    [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral %@, connected", peripheral.name);
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"connectoed to %@\n", peripheral.name]];
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"Failed to connect to peripheral: %@", peripheral.name);
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Failed connecting to %@\n", peripheral.name]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"Disconnected from peripheral: %@", peripheral.name);
     self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"disconnecting from %@\n", peripheral.name]];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for(CBService *service in peripheral.services){
        NSLog(@"Discovered service %@", service);
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Discovered service %@\n",service]];
        NSLog(@"Discovering characteristics for service %@", service);
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Discovered characteristics for service %@\n",service]];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@ for service %@", characteristic, service);
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Discovered characteristic %@ for service %@\n", characteristic, service]];
        NSLog(@"Subscriping to characterisitic %@ ", characteristic);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"713D0003-503E-4C75-BA94-3148F18D941E"]])
        {
            self.interestingCharacterisitic = characteristic;
            self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Pushing to characterisitics %@\n", characteristic]];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"713D0002-503E-4C75-BA94-3148F18D941E"]])
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Subscriping to characterisitics %@\n", characteristic]];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    }
    NSLog(@"Update notification for characteristic %@", characteristic);
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Update notification for characteristic %@\n", characteristic]];
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error) {
        NSLog(@"Error writing characteristic value: %@", [error localizedDescription]);
    }
    NSLog(@"Write done for characteristic %@", characteristic);
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"Write done for characteristic %@\n", characteristic]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.discoveredPeripheral count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"devicecell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"devicecell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = [(CBPeripheral*)[self.discoveredPeripheral objectAtIndex:indexPath.row] name];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.myPeripheral = [self.discoveredPeripheral objectAtIndex:indexPath.row];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [_myCentralManager stopScan];
    [_myCentralManager connectPeripheral:self.myPeripheral options:nil];
}

#pragma mark - UITextViewDelegate


@end
