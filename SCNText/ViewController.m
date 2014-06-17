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
@property (nonatomic) IBOutlet UIButton *animateButton;
@property (nonatomic) IBOutlet SCNView *sceneView;
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

    [self.sceneView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusTextField:)]];

    SCNScene *scene = [SCNScene scene];
    self.sceneView.scene = scene;

    SCNNode *cameraNode = [SCNNode node];
    cameraNode.position = SCNVector3Make(0, 0, 2);
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    self.sceneView.pointOfView = cameraNode;

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

-(void)focusTextField:(id)sender {
    [self.textField becomeFirstResponder];
}

- (IBAction)clearText:(id)sender {
    self.textField.text = @"";
    [self textDidChange:nil];
}

- (IBAction)toggleAnimate:(id)sender {
    self.animating = ! self.isAnimating;

    if (self.animating) {
        [self.animateButton setTitle:@"Stop Animating" forState:UIControlStateNormal];
        [self animateText];
    } else {
        [self.animateButton setTitle:@"Start Animating" forState:UIControlStateNormal];
        self.textNode.rotation = SCNVector4Zero;
    }
}

- (void)animateText {
    if (self.isAnimating) {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
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