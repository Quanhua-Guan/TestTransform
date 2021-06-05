//
//  ViewController.m
//  TestTransform
//
//  Created by 宇园 on 2021/6/4.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *father;
@property (weak, nonatomic) IBOutlet UIView *son;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGAffineTransform t = CGAffineTransformMakeScale(0.5, 0.5);
    t = CGAffineTransformTranslate(t, 55, 16);
    t = CGAffineTransformRotate(t, 6);
    
    _son.transform = t;
}

- (IBAction)test:(id)sender {
    {
        CGPoint p0 = CGPointMake(3, 5);
        CGPoint p1 = [self transformChildPoint:p0
                   toSuperLayerWithChildCenter:_son.center
                                     childSize:_son.bounds.size
                                childTransform:_son.transform];
        CGPoint p11 = [_father convertPoint:p0 fromView:_son];
        
        CGPoint p00 = [_father convertPoint:p11 toView:_son];
        CGPoint p000 = [self transformSuperPoint:p11
                     toChildLayerWithChildCenter:_son.center
                                       childSize:_son.bounds.size
                                  childTransform:_son.transform];
        
        if (CGPointEqualToPoint(p1, p11)) {
            NSLog(@"p1 == p11");
        }
        if (CGPointEqualToPoint(p00, p000)) {
            NSLog(@"p00 == p000");
        }
        
    }
    {
        /// 从子视图将坐标转换成父视图坐标
        
        CGFloat sonCenterX = _son.center.x, sonCenterY = _son.center.y;
        CGFloat sonBoundsWidth = _son.bounds.size.width, sonBoundsHeight = _son.bounds.size.height;
        
        // 计算子视图未执行变换前的中心点+大小 center + bounds.size
        ///
        /// 构造一个中间视图 父视图 -> 中间视图 -> 子视图,
        /// 且中间视图未进行任何旋转缩放平移操作.
        /// 且中间视图和子视图大小一致.
        CGRect sonFrame = CGRectMake(sonCenterX - sonBoundsWidth / 2, sonCenterY - sonBoundsHeight / 2, sonBoundsWidth, sonBoundsHeight);
        
        // 计算子视图相对中间视图的变换(和子视图相对于父视图的变换是一致的)
        CGAffineTransform t = _son.transform;
        
        // 由于 UIView 视图的锚点默认设置为视图中心点, 所以需要对变换矩阵进行一个处理.
        CGFloat w = sonBoundsWidth / 2, h = sonBoundsHeight / 2; // 计算中间视图宽度和高度的二分之一.
        
        ///                           [ a  b  0 ]
        /// [x`, y`, 1] = [x, y, 1] x | c  d  0 |
        ///                           [ tx ty 1 ]
        
        /// 为了保证子视图锚点位置在子视图自身中心点, 需要进行操作:
        /// 变换前 移动一个 (-w, -h) 距离, 变换后再移动一个 (w, h) 距离进行抵消.
        ///
        /// 靠近点的位置即为前置位置, 远离点的位置即为后置位置, 所以有 前乘 和 后乘 的区别.
        // 前乘 将子视图中心点移动到中间视图原点
        t = CGAffineTransformConcat(CGAffineTransformMakeTranslation(-w, -h), t);
        // 后乘 将子视图中心点移动回中间视图中心点(假设子视图未做任何变换的情况下)
        t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(w, h));
        
        /// 将子视图上的点 p0 转换到父视图坐标系上的点 p1
        // p1 = p0 * t
        // 假设 t`为 t的逆矩阵, 则 p1 * t` = p0 * t * t` = p0  <=== 推导将父视图坐标点转换到子视图坐标系, p0即为子视图上的点
        CGPoint p0 = CGPointMake(3, 5);
        // 先将子视图上的点转换成中间视图坐标系上的点
        CGPoint p1 = CGPointApplyAffineTransform(p0, t);
        // 再将中间视图上的点转换成父视图坐标系上的点
        p1.x += sonFrame.origin.x;
        p1.y += sonFrame.origin.y;
        
        // 使用UIView自带方法验证, 预期结果 p2 == p1
        CGPoint p2 = [_father convertPoint:p0 fromView:_son];
        //CGPoint p2_ = [_son convertPoint:p0 fromView:_father];
        
        ///////
        /////// 父视图上的点 p1 转换到子视图坐标系上的点 p0.
        /// 根据上面过程推导 p1 * t` = p0 * t * t` = p0, 其中 t` 为 t 的逆矩阵, 使用 CGAffineTransformInvert 进行求解逆矩阵
        ///
        /// 首先, 将父视图上的点 p1 转换到中间视图坐标系, 即 CGPointMake(p1.x - sonFrame.origin.x, p1.y - sonFrame.origin.y)
        /// 同时, 计算出 矩阵 t`
        ///
        /// 工具公式算出 p00, 预期结果 p00 == p0
        ///////
        CGAffineTransform t_ = CGAffineTransformInvert(t);
        CGPoint p00 = CGPointApplyAffineTransform(CGPointMake(p1.x - sonFrame.origin.x, p1.y - sonFrame.origin.y), t_);
        
        if (CGPointEqualToPoint(p2, p1)) {
            NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
        if (CGPointEqualToPoint(p00, p0)) {
            NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
    }
}

- (CGPoint)transformChildPoint:(CGPoint)childPoint
   toSuperLayerWithChildCenter:(CGPoint)childCenter // 这个点间接定位了父视图的原点
                     childSize:(CGSize)childSize // 子视图未进行变换时的大小
                childTransform:(CGAffineTransform)childTransform // 子视图相对父视图的变换, 锚点为子视图自身的中心点
{
    CGAffineTransform t = childTransform;
    // 子视图锚点为其中心点
    t = CGAffineTransformConcat(CGAffineTransformMakeTranslation(-childSize.width / 2, -childSize.height / 2), t);
    t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(childSize.width / 2, childSize.height / 2));
    
    // middlePoint = childPoint * t
    // 将子视图坐标转换成中间视图坐标
    CGPoint middlePoint = CGPointApplyAffineTransform(childPoint, t);
    
    // 将中间视图坐标转换成父视图坐标
    CGPoint superPoint = CGPointMake(middlePoint.x + (childCenter.x - childSize.width / 2),
                                     middlePoint.y + (childCenter.y - childSize.height / 2));
    
    return  superPoint;
}

- (CGPoint)transformSuperPoint:(CGPoint)superPoint
   toChildLayerWithChildCenter:(CGPoint)childCenter // 这个点间接定位了父视图的原点
                     childSize:(CGSize)childSize // 子视图未进行变换时的大小
                childTransform:(CGAffineTransform)childTransform // 子视图相对父视图的变换, 锚点为子视图自身的中心点
{
    CGAffineTransform t = childTransform;
    // 子视图锚点为其中心点
    t = CGAffineTransformConcat(CGAffineTransformMakeTranslation(-childSize.width / 2, -childSize.height / 2), t);
    t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(childSize.width / 2, childSize.height / 2));
    
    // 假设 t` 是 t 的逆矩阵, t` * t = I(单位矩阵)
    // middlePoint = childPoint * t
    // middlePoint * t` = childPoint * t * t` = childPoint
    // 将子视图坐标转换成中间视图坐标
    CGPoint middlePoint = CGPointMake(superPoint.x - (childCenter.x - childSize.width / 2),
                                      superPoint.y - (childCenter.y - childSize.height / 2));
    CGPoint childPoint = CGPointApplyAffineTransform(middlePoint, CGAffineTransformInvert(t));
    
    return childPoint;
}

@end
