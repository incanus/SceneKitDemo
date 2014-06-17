//
//  ViewController.m
//  SCNText
//
//  Created by Justin R. Miller on 6/16/14.
//  Copyright (c) 2014 Mapbox. All rights reserved.
//

#import "ViewController.h"

#import <SceneKit/SceneKit.h>

@interface ViewController ()

@property (nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) IBOutlet UIButton *cameraResetButton;
@property (nonatomic) IBOutlet UIButton *animateButton;
@property (nonatomic) IBOutlet SCNView *sceneView;
@property (nonatomic) SCNNode *cameraNode;
@property (nonatomic) SCNNode *textNode;
@property (nonatomic, getter=isAnimating) BOOL animating;

@end

@implementation ViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.sceneView.backgroundColor = [UIColor clearColor];

    self.textField.center = CGPointMake(self.view.bounds.size.width / 2, -50);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.textField];

    [self.sceneView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCamera:)]];
    [self.sceneView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomCamera:)]];
    [self.sceneView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cycleExtrusion:)]];

    SCNScene *scene = [SCNScene scene];
    self.sceneView.scene = scene;

    self.cameraNode = [SCNNode node];
    self.cameraNode.position = SCNVector3Make(0, 0, 2);
    self.cameraNode.camera = [SCNCamera camera];
    self.cameraNode.camera.zNear = 0.1;
    [scene.rootNode addChildNode:self.cameraNode];
    self.sceneView.pointOfView = self.cameraNode;
    self.cameraResetButton.hidden = YES;

    SCNText *sceneText = [SCNText textWithString:self.textField.text extrusionDepth:2];
    SCNMaterial *frontMaterial = [SCNMaterial material];
    frontMaterial.diffuse.contents = [UIImage imageNamed:@"light_wood.jpg"];
    SCNMaterial *backMaterial = [SCNMaterial material];
    backMaterial.diffuse.contents = [UIImage imageNamed:@"light_wood.jpg"];
    SCNMaterial *sideMaterial = [SCNMaterial material];
    sideMaterial.diffuse.contents = [UIImage imageNamed:@"dark_wood.jpg"];
    sceneText.materials = @[ frontMaterial, backMaterial, sideMaterial ];

    CGFloat textScale = 1.0 / sceneText.font.pointSize;

    self.textNode = [SCNNode nodeWithGeometry:sceneText];
    self.textNode.scale = SCNVector3Make(textScale, textScale, textScale);
    [scene.rootNode addChildNode:self.textNode];

    [self recenterText];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self focusTextField:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)focusTextField:(id)sender {
    [self.textField becomeFirstResponder];
}

- (void)panCamera:(UIPanGestureRecognizer *)pan {
    self.cameraNode.rotation = SCNVector4Make(0, 1, 0, ([pan translationInView:pan.view].x / 1000) * M_PI);
    self.cameraResetButton.hidden = NO;
}

- (void)zoomCamera:(UIPinchGestureRecognizer *)pinch {
    CGFloat z = self.cameraNode.position.z * (1 / pinch.scale);
    z = fmaxf(1.0, z);
    z = fminf(4.0, z);
    self.cameraNode.position = SCNVector3Make(0, 0, z);
    self.cameraResetButton.hidden = NO;
}

- (void)cycleExtrusion:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        SCNText *sceneText = (SCNText *)self.textNode.geometry;
        CGFloat newDepth = sceneText.extrusionDepth + 1.0;
        if (newDepth > 10.0) newDepth = 2.0;
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        sceneText.extrusionDepth = newDepth;
        [SCNTransaction commit];
    }
}

- (IBAction)clearText:(id)sender {
    self.textField.text = @"";
    [self textDidChange:nil];
}

- (IBAction)resetCamera:(id)sender {
    self.cameraResetButton.hidden = YES;
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.5];
    self.cameraNode.position = SCNVector3Make(0, 0, 2);
    self.cameraNode.rotation = SCNVector4Zero;
    [SCNTransaction commit];
}

- (IBAction)toggleAnimate:(id)sender {
    self.animating = ! self.isAnimating;
    if (self.animating) {
        [self.animateButton setTitle:@"Stop Animating" forState:UIControlStateNormal];
        [self animateText];
    } else {
        [self.animateButton setTitle:@"Start Animating" forState:UIControlStateNormal];
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        self.textNode.rotation = SCNVector4Zero;
        [SCNTransaction commit];
    }
}

- (void)animateText {
    if (self.isAnimating) {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.5];
        self.textNode.rotation = SCNVector4Make(1, 0, 0, 2 * M_PI);
        [SCNTransaction setCompletionBlock:^{
            self.textNode.rotation = SCNVector4Zero;
            [self animateText];
        }];
        [SCNTransaction commit];
    }
}

- (void)textDidChange:(NSNotification *)notification {
    SCNText *sceneText = (SCNText *)self.textNode.geometry;
    sceneText.string = self.textField.text;
    [self recenterText];
}

- (void)recenterText {
    SCNText *sceneText = (SCNText *)self.textNode.geometry;
    CGFloat textScale = 1.0 / sceneText.font.pointSize;
    self.textNode.position = SCNVector3Make(-sceneText.textSize.width / 2 * textScale, -sceneText.textSize.height / 2 * textScale, 0);
}

@end
