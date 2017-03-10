/*
 CTAssetsViewController.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "CTAssetsPickerCommon.h"
#import "CTAssetsPickerController.h"
#import "CTAssetsViewController.h"
#import "CTAssetsViewCell.h"
#import "CTAssetsSupplementaryView.h"
#import "CTAssetsPageViewController.h"
#import "CTAssetsViewControllerTransition.h"
#import "NSBundle+CTAssetsPickerController.h"


//#import "Global.h"


NSString * const CTAssetsViewCellIdentifier = @"CTAssetsViewCellIdentifier";
NSString * const CTAssetsSupplementaryViewIdentifier = @"CTAssetsSupplementaryViewIdentifier";



@interface CTAssetsPickerController ()

- (void)dismiss:(id)sender;
- (void)finishPickingAssets:(id)sender;

- (NSString *)toolbarTitle;
- (UIView *)noAssetsView;

@end



@interface CTAssetsViewController () <CTAssetsViewCellDelegate>

@property (nonatomic, weak) CTAssetsPickerController *picker;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *selectedAssets;

@end





@implementation CTAssetsViewController


- (id)init
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UICollectionViewFlowLayout *layout = [self collectionViewFlowLayoutOfOrientation:interfaceOrientation];
    
    if (self = [super initWithCollectionViewLayout:layout])
    {
        self.collectionView.allowsMultipleSelection = YES;
        
        [self.collectionView registerClass:CTAssetsViewCell.class
                forCellWithReuseIdentifier:CTAssetsViewCellIdentifier];
        
        [self.collectionView registerClass:CTAssetsSupplementaryView.class
                forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                       withReuseIdentifier:CTAssetsSupplementaryViewIdentifier];
        
        self.preferredContentSize = CTAssetPickerPopoverContentSize;
    }
    
    [self addNotificationObserver];
    //    [self addGestureRecognizer];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    self.selectedAssets = [[NSMutableArray alloc]init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupButtons];
    [self setupToolbar];
    [self setupAssets];
}

- (void)dealloc
{
    [self removeNotificationObserver];
}


#pragma mark - Accessors

- (CTAssetsPickerController *)picker
{
    CTAssetsPickerController *vc = (CTAssetsPickerController *)self.navigationController.parentViewController;
    return vc;
}


#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    UICollectionViewFlowLayout *layout = [self collectionViewFlowLayoutOfOrientation:toInterfaceOrientation];
    [self.collectionView setCollectionViewLayout:layout animated:YES];
}


#pragma mark - Setup

- (void)setupViews
{
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)setupButtons
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                     style:UIBarButtonItemStyleDone
                                    target:self.picker
                                    action:@selector(dismiss:)];
}

- (void)setupToolbar
{
    self.toolbarItems = self.picker.toolbarItems;
    
    //“预览”按钮
    [[self.toolbarItems firstObject] setTarget:self];
    [[self.toolbarItems firstObject] setAction:@selector(previewPhotos)];
    
    //“完成”按钮
    [[self.toolbarItems lastObject] setTarget:self.picker];
    [[self.toolbarItems lastObject] setAction:@selector(finishPickingAssets:)];
    if (self.picker.alwaysEnableDoneButton)
        [self.toolbarItems lastObject].enabled = YES;
    
    else
        [self.toolbarItems lastObject].enabled = (self.picker.selectedAssets.count > 0);
    
}

- (void)setupAssets
{
    
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    else
        return;
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            BOOL shouldShowAsset;
            
            if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldShowAsset:)])
                shouldShowAsset = [self.picker.delegate assetsPickerController:self.picker shouldShowAsset:asset];
            else
                shouldShowAsset = YES;
            
            if (shouldShowAsset)
                [self.assets addObject:asset];
        }
        else
        {
            [self reloadData];
        }
    };
    
    [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
}


-(void)previewPhotos {
    if (!self.picker.selectedAssets) {
        return;
    }
    CTAssetsPageViewController *vc = [[CTAssetsPageViewController alloc] initWithAssets:self.picker.selectedAssets];
    vc.pageIndex = 0;
    
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark - Collection View Layout

- (UICollectionViewFlowLayout *)collectionViewFlowLayoutOfOrientation:(UIInterfaceOrientation)orientation
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.itemSize             = CTAssetThumbnailSize;
    layout.footerReferenceSize  = CGSizeMake(0, 47.0);
    
    if (UIInterfaceOrientationIsLandscape(orientation) && (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad))
    {
        layout.sectionInset            = UIEdgeInsetsMake(9.0, 2.0, 0, 2.0);
        layout.minimumInteritemSpacing = (CTIPhone6Plus) ? 1.0 : ( (CTIPhone6) ? 2.0 : 3.0 );
        layout.minimumLineSpacing      = (CTIPhone6Plus) ? 1.0 : ( (CTIPhone6) ? 2.0 : 3.0 );
    }
    else
    {
        layout.sectionInset            = UIEdgeInsetsMake(9.0, 0, 0, 0);
        layout.minimumInteritemSpacing = (CTIPhone6Plus) ? 0.5 : ( (CTIPhone6) ? 1.0 : 2.0 );
        layout.minimumLineSpacing      = (CTIPhone6Plus) ? 0.5 : ( (CTIPhone6) ? 1.0 : 2.0 );
    }
    
    return layout;
}


#pragma mark - Notifications

- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(assetsLibraryChanged:)
                   name:ALAssetsLibraryChangedNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(selectedAssetsChanged:)
                   name:CTAssetsPickerSelectedAssetsChangedNotification
                 object:nil];
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CTAssetsPickerSelectedAssetsChangedNotification object:nil];
}


#pragma mark - Assets Library Changed

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    // Reload all assets
    if (notification.userInfo == nil)
        [self performSelectorOnMainThread:@selector(reloadAssets) withObject:nil waitUntilDone:NO];
    
    // Reload effected assets groups
    if (notification.userInfo.count > 0)
        [self reloadAssetsGroupForUserInfo:notification.userInfo];
}


#pragma mark - Reload Assets Group

- (void)reloadAssetsGroupForUserInfo:(NSDictionary *)userInfo
{
    NSSet *URLs = [userInfo objectForKey:ALAssetLibraryUpdatedAssetGroupsKey];
    NSURL *URL  = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", URL];
    NSArray *matchedGroups = [URLs.allObjects filteredArrayUsingPredicate:predicate];
    
    // Reload assets if current assets group is updated
    if (matchedGroups.count > 0)
        [self performSelectorOnMainThread:@selector(reloadAssets) withObject:nil waitUntilDone:NO];
}



#pragma mark - Selected Assets Changed

- (void)selectedAssetsChanged:(NSNotification *)notification
{
    NSArray *selectedAssets = (NSArray *)notification.object;
    
    [[self.toolbarItems objectAtIndex:2] setTitle:[self.picker toolbarTitle]];
    
    [self.navigationController setToolbarHidden:(selectedAssets.count == 0) animated:YES];
    
    // Reload assets for calling de/selectAsset method programmatically
    //    [self.collectionView reloadData];
}




#pragma mark - Reload Assets

- (void)reloadAssets
{
    self.assets = nil;
    [self setupAssets];
}



#pragma mark - Reload Data

- (void)reloadData
{
    if (self.assets.count > 0)
    {
        [self.collectionView reloadData];
        
        if (self.collectionView.contentOffset.y <= 0)
            [self.collectionView setContentOffset:CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height)];
    }
    else
    {
        [self showNoAssets];
    }
}


#pragma mark - No assets

- (void)showNoAssets
{
    self.collectionView.backgroundView = [self.picker noAssetsView];
    [self setAccessibilityFocus];
}

- (void)setAccessibilityFocus
{
    self.collectionView.isAccessibilityElement  = YES;
    self.collectionView.accessibilityLabel      = self.collectionView.backgroundView.accessibilityLabel;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.collectionView);
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CTAssetsViewCellIdentifier
                                                                       forIndexPath:indexPath];
    
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldEnableAsset:)])
        cell.enabled = [self.picker.delegate assetsPickerController:self.picker shouldEnableAsset:asset];
    else
        cell.enabled = YES;
    
    cell.picked = NO; //复位
    [cell bind:asset];
    cell.indexPath = indexPath;
    cell.delegate = self;
    
    if ([self.picker.selectedAssets containsObject:asset]) {
        cell.picked = YES;
    }
    
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                       withReuseIdentifier:CTAssetsSupplementaryViewIdentifier
                                              forIndexPath:indexPath];
    
    [view bind:self.assets];
    
    if (self.assets.count == 0)
        view.hidden = YES;
    
    return view;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    CTAssetsViewCell *cell = (CTAssetsViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (!cell.isEnabled)
        return NO;
    else if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldSelectAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldSelectAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPageViewController *vc = [[CTAssetsPageViewController alloc] initWithAssets:self.assets];
    vc.pageIndex = indexPath.item;
    
    [self.navigationController pushViewController:vc animated:YES];
}

//- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
//    [self.selectedAssets removeObject:asset];
//    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldDeselectAsset:)])
//        return [self.picker.delegate assetsPickerController:self.picker shouldDeselectAsset:asset];
//    else
//        return YES;
//}

//- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
//
//    [self.picker deselectAsset:asset];
//
//    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didDeselectAsset:)])
//        [self.picker.delegate assetsPickerController:self.picker didDeselectAsset:asset];
//}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldHighlightAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldHighlightAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didHighlightAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didHighlightAsset:asset];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didUnhighlightAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didUnhighlightAsset:asset];
}

#pragma mark - CTAssetsViewCellDelegate
-(void)didPickedCellAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    CTAssetsViewCell *cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    //首先判断cell可选不可选
    if (!cell.isEnabled)
        return;
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldSelectAsset:)]) {
        if (![self.picker.delegate assetsPickerController:self.picker shouldSelectAsset:asset]) {
            return;
        }
    }
    
    //其次判断cell是否已被选
    if (cell.picked) {
        //已经被选，则撤销勾选
        cell.picked = NO;
        
        [self.selectedAssets removeObject:asset];
        [self.picker deselectAsset:asset];
        if (self.picker.selectedAssets.count) {
            [self.toolbarItems lastObject].enabled = YES;
        }else {
            [self.toolbarItems lastObject].enabled = NO;
        }
        
        if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldDeselectAsset:)]) {
            if (![self.picker.delegate assetsPickerController:self.picker shouldDeselectAsset:asset]) {
                return;
            }
        }
    } else {
        //没有被选中，则勾选
        cell.picked = YES;
        
        [self.selectedAssets addObject:asset];
        [self.picker selectAsset:asset];//导致错乱
        
        if (![self.toolbarItems lastObject].enabled) {
            [self.toolbarItems lastObject].enabled = YES;
        }
        
        if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didSelectAsset:)])
            [self.picker.delegate assetsPickerController:self.picker didSelectAsset:asset];
    }
    
    
    
    
    
}
@end
