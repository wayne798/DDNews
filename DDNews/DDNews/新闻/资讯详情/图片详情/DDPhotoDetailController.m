//
//  DDPhotoDetailController.m
//  DDNews
//
//  Created by Dvel on 16/4/18.
//  Copyright © 2016年 Dvel. All rights reserved.
//

#import "DDPhotoDetailController.h"
#import "DDPhotoModel.h"
#import "DDPhotoDetailModel.h"
#import "DDPhotoScrollView.h"
#import "DDPhotoDescView.h"
#import "DDBottomView.h"

#import "JZNavigationExtension.h"
#import "UIImageView+WebCache.h"
#import "UIView+Extension.h"
#import "JT3DScrollView.h"

@interface DDPhotoDetailController () <UIScrollViewDelegate>
@property (nonatomic, strong) DDPhotoModel *photoModel;
@property (nonatomic, assign) NSInteger currentPage;
// UI
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) JT3DScrollView *imageScrollView;
@property (nonatomic, strong) DDPhotoDescView *photoDescView;
@property (nonatomic, strong) DDBottomView *bottomView;

@property (nonatomic, assign) BOOL isDisappear;
@end

@implementation DDPhotoDetailController

- (instancetype)initWithPhotosetID:(NSString *)photosetID
{
	self = [super init];
	if (self) {
		[DDPhotoModel photoModelWithPhotosetID:(NSString *)photosetID complection:^(DDPhotoModel *photoModel) {
			self.photoModel = photoModel;
		}];
		self.automaticallyAdjustsScrollViewInsets = NO;
	}
	return self;
}

- (void)viewDidLoad
{
	self.view.backgroundColor = [UIColor colorWithRed:0.174 green:0.174 blue:0.164 alpha:1.000];
	self.navigationController.fullScreenInteractivePopGestureRecognizer = YES;
	
	[self.view addSubview:self.backButton];
	[self.view addSubview:self.bottomView];
}

/** 模型初始化后，开始搭建需要网络加载后才显示的UI。 */
- (void)setPhotoModel:(DDPhotoModel *)photoModel
{
	_photoModel = photoModel;
	[self.view insertSubview:self.imageScrollView belowSubview:self.backButton];
	[self addObserver:self forKeyPath:@"currentPage" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self setValue:@(_imageScrollView.currentPage) forKey:@"currentPage"];
}


#pragma mark - KVO
static int temp = -1;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	// 获取新旧索引
//	int oldIndex = [change[@"old"] intValue]; // 暂时没用到，想用来写图片大小恢复的。
	int newIndex = [change[@"new"] intValue];
	
	// 防止玩命赋值，只有发生变化了才进行下一步操作。
	if (temp == newIndex) {return;}
	temp = newIndex;
	
	// 如果已经消失了，就不展现描述文本了。
	if (_isDisappear == YES) {return;}
	
	DDPhotoDetailModel *detailModel = _photoModel.photos[newIndex];
	// 先remove
	[_photoDescView removeFromSuperview];
	// 再加入
	_photoDescView = [[DDPhotoDescView alloc] initWithTitle:_photoModel.setname
													   desc:detailModel.note
													  index:newIndex
												 totalCount:_photoModel.photos.count];
	[self.view insertSubview:_photoDescView belowSubview:self.bottomView];
}


#pragma mark - getter
- (UIButton *)backButton
{
	if (_backButton == nil) {
		_backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 25, 40, 40)];
		[_backButton setImage:[UIImage imageNamed:@"imageset_back_live"] forState:UIControlStateNormal];
		[_backButton setImage:[UIImage imageNamed:@"imageset_back"] forState:UIControlStateSelected];
		[_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
	}
	return _backButton;
}


- (JT3DScrollView *)imageScrollView
{
	if (_imageScrollView == nil) {
		// 设置大ScrollView  40:适当提高下imageView的高度，否则上面显得太空洞
		_imageScrollView = [[JT3DScrollView alloc] initWithFrame:CGRectMake(0, 0, ScrW, ScrH - 40)];
		_imageScrollView.contentSize = CGSizeMake(_photoModel.photos.count * ScrW, ScrH - 40);
		_imageScrollView.showsHorizontalScrollIndicator = NO;
		_imageScrollView.effect = arc4random_uniform(3) + 1; // 切换的动画效果,随机枚举中的1，2，3三种效果。
		_imageScrollView.clipsToBounds = YES;
		_imageScrollView.delegate = self;

		// 设置小ScrollView（装载imageView的scrollView）
		for (int i = 0; i < self.photoModel.photos.count; i++) {
			DDPhotoDetailModel *detailModel = self.photoModel.photos[i];
			DDPhotoScrollView *photoScrollView = [[DDPhotoScrollView alloc] initWithFrame:CGRectMake(ScrW * i, 0, ScrW, ScrH - 40) urlString:detailModel.imgurl];
			// singleTapBlock回调：让所有UI，除了图片，全部消失
			__weak typeof(self) weakSelf = self;
			photoScrollView.singleTapBlock = ^{
				NSLog(@"tap~");
				// 如果已经消失，就出现
				if (_isDisappear == YES) {
					[weakSelf.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
						if (![obj isKindOfClass:[JT3DScrollView class]]) {
							[UIView animateWithDuration:0.5 animations:^{
								obj.alpha = 1;
								weakSelf.view.backgroundColor = [UIColor colorWithRed:0.174 green:0.174 blue:0.164 alpha:1.000];
							} completion:^(BOOL finished) {
								obj.userInteractionEnabled = YES;
							}];
						}
					}];
					_isDisappear = NO;
//					return;
				} else { // 消失
					[weakSelf.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
						if (![obj isKindOfClass:[JT3DScrollView class]]) {
							[UIView animateWithDuration:0.5 animations:^{
								obj.alpha = 0;
								weakSelf.view.backgroundColor = [UIColor blackColor];
							} completion:^(BOOL finished) {
								obj.userInteractionEnabled = NO;
							}];
						}
					}];
					_isDisappear = YES;
				}
				
			};
			[_imageScrollView addSubview:photoScrollView];
		}
	}
	return _imageScrollView;
}

- (DDBottomView *)bottomView
{
	if (_bottomView == nil) {
		_bottomView = [[NSBundle mainBundle] loadNibNamed:@"DDBottomView" owner:nil options:nil].lastObject;
		_bottomView.frame = CGRectMake(0, ScrH - 40, ScrW, 40);
	}
	return _bottomView;
}

#pragma mark -
- (void)backButtonClick
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (void)dealloc
{
	temp = -1;
	[self removeObserver:self forKeyPath:@"currentPage"];
}

@end

