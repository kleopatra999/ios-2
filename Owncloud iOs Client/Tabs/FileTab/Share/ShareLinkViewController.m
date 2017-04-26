//
//  ShareLinkViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 25/04/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "ShareLinkViewController.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "UtilsFramework.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "ManageSharesDB.h"

#define shareLinkViewNibName @"ShareLinkViewController"

//Cells and Sections
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"


//Nº of Rows
#define optionsShownWithShareLinkEnableAndAllowEditing 4
#define optionsShownWithShareLinkEnableWithoutAllowEditing 3
#define optionsShownWithShareLinkDisable 0

//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//alert share password
#define password_alert_view_tag 601

//permissions value to not update them
#define k_permissions_do_not_update 0

//mail subject key
#define k_subject_key_activityView @"subject"


@interface ShareLinkViewController ()

@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;

@end

@implementation ShareLinkViewController


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto{
    
    if ((self = [super initWithNibName:shareLinkViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.updatedOCShare = sharedDto;
        
        self.isPasswordProtectEnabled = false;
        self.isExpirationDateEnabled = false;

        
        self.manageNetworkErrors = [ManageNetworkErrors new];
        self.manageNetworkErrors.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
}


#pragma mark - Action Methods

- (void) didSelectCloseView {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) reloadView {
    
    self.isPasswordProtectEnabled = false;
    self.isExpirationDateEnabled = false;

    [self.shareLinkOptionsTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else if (section == 1){
         return 1;
    }else if (section == 2) {
        return 1;
    }else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    //if (indexPath.section == 0) {
        
    
    
//        ShareLinkOptionCell *shareLinkOptionCell = (ShareLinkOptionCell *)[tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
//        
//        if (shareLinkOptionCell == nil) {
//            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
//            shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
//        }
//        
//        //shareLinkOptionCell.fileName.text = [self.updatedOCShare.shareWithDisplayName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        
//        shareLinkOptionCell.optionName = self.updatedOCShare.name;
//        shareLinkOptionCell.
//        cell = shareLinkOptionCell;
        
   // }
    
    return [self getCellOptionShareLinkByTableView:tableView andIndex:indexPath];;
}

#pragma mark - cells

- (UITableViewCell *) getCellOptionShareLinkByTableView:(UITableView *) tableView andIndex:(NSIndexPath *) indexPath {
    //TODO:update with data
    ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];

    if (shareLinkOptionCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
        shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
    }

    [shareLinkOptionCell.optionSwith removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];

    switch (indexPath.row) {
        case 0:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"set_expiration_time", nil);

            if (self.isExpirationDateEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.text = [self stringOfDate:[NSDate dateWithTimeIntervalSince1970: self.updatedOCShare.expirationDate]];
            }else{
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.text = @"";
            }
            [shareLinkOptionCell.optionSwith setOn:self.isExpirationDateEnabled animated:false];

//            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(expirationTimeSwithValueChanged:) forControlEvents:UIControlEventValueChanged];

            break;
//
//        case 1:
//            shareLinkOptionCell.optionName.text = NSLocalizedString(@"password_protect", nil);
//
//            if (self.isPasswordProtectEnabled) {
//                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
//                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
//                shareLinkOptionCell.optionDetail.text = NSLocalizedString(@"secured_link", nil);
//            } else {
//                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
//                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
//                shareLinkOptionCell.optionDetail.text = @"";
//            }
//            [shareLinkOptionCell.optionSwith setOn:self.isPasswordProtectEnabled animated:false];
//
// //           [shareLinkOptionCell.optionSwith addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
//
//            break;
//
//        case 2:
//            shareLinkOptionCell.optionName.text = NSLocalizedString(@"allow_editing", nil);

//            if (self.isAllowEditingEnabled) {
//                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
//                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
//            } else {
//                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
//                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
//            }
//            shareLinkOptionCell.optionDetail.text = @"";
//            [shareLinkOptionCell.optionSwith setOn:self.isAllowEditingEnabled animated:false];

 //           [shareLinkOptionCell.optionSwith addTarget:self action:@selector(allowEditingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];

 //           break;

        default:
            //Not expected
            DLog(@"Not expected");
            break;
    }

    return shareLinkOptionCell;

}


#pragma mark -
- (void) didSelectSetExpirationDateLink {
   // [self launchDatePicker];
}

- (void) didSelectSetPasswordLink {
    //[self showPasswordView];
}


#pragma mark - convert

- (NSString *) stringOfDate:(NSDate *) date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"title_view_share_link_options", nil);
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectCloseView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
