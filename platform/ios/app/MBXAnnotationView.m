#import "MBXAnnotationView.h"
#import "MGLSignpost.h"

@interface MBXAnnotationView ()
@property (nonatomic, readwrite, nonnull) os_log_t log;
@property (nonatomic, readwrite) os_signpost_id_t signpost;
@end

@implementation MBXAnnotationView

- (void)layoutSubviews {
    [super layoutSubviews];

    CAShapeLayer *squareLayer = [CAShapeLayer layer];
    [squareLayer setPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 10, 10)] CGPath]];
    [[self layer] addSublayer:squareLayer];
    self.layer.borderColor = [UIColor blueColor].CGColor;
    self.layer.borderWidth = 1;
    self.layer.cornerRadius = 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    self.layer.borderColor = selected ? [UIColor purpleColor].CGColor : [UIColor whiteColor].CGColor;
    self.layer.borderWidth = selected ? 2.0 : 0;
}

- (void)setDragState:(MGLAnnotationViewDragState)dragState animated:(BOOL)animated
{
    [super setDragState:dragState animated:NO];

    switch (dragState) {
        case MGLAnnotationViewDragStateNone:
            break;
        case MGLAnnotationViewDragStateStarting: {
            [UIView animateWithDuration:.4 delay:0 usingSpringWithDamping:.4 initialSpringVelocity:.5 options:UIViewAnimationOptionCurveLinear animations:^{
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
            } completion:nil];
            break;
        }
        case MGLAnnotationViewDragStateDragging:
            break;
        case MGLAnnotationViewDragStateCanceling:
            break;
        case MGLAnnotationViewDragStateEnding: {
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
            [UIView animateWithDuration:.4 delay:0 usingSpringWithDamping:.4 initialSpringVelocity:.5 options:UIViewAnimationOptionCurveLinear animations:^{
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            } completion:nil];
            break;
        }
    }

}

- (void)drawRect:(CGRect)rect {
    MGL_SIGNPOST_BEGIN(_log, _signpost, "drawAnnotation", "draw");
    NSLog(@"hi!");
    MGL_SIGNPOST_END(_log, _signpost, "drawAnnotation", "draw");
}
//- (void)draw
@end
