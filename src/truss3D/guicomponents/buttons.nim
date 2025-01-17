import uielements, labels
import truss3D/gui

type Button* = ref object of UiElement
    onClick*: proc(){.closure.}
    label*: Label


proc new*(
  _: typedesc[Button];
  pos, size: IVec2;
  text: string;
  color = vec4(1);
  nineSliceSize = 0f;
  backgroundTex: Texture or string = Texture(0);
  backgroundColor = vec4(0.3, 0.3, 0.3, 1);
  fontColor = vec4(1);
  anchor = {left, top};
  onClick = (proc(){.closure.})(nil)
): Button =
  result = Button(
    pos: pos,
    size: size,
    color: color,
    anchor: anchor,
    onClick: onClick,
    isNineSliced: nineSliceSize > 0,
    nineSliceSize: nineSliceSize,
    backgroundColor: backgroundColor)
  result.label = Label.new(pos, size, text, fontColor, vec4(0), anchor)
  when backgroundTex is string:
    result.backgroundTex = genTexture()
    readImage(backgroundTex).copyTo result.backgroundTex
  else:
    result.backgroundTex = backgroundTex


method update*(button: Button, dt: float32, offset = ivec2(0), relativeTo = false) =
  if button.isOver(offset = offset, relativeTo = relativeTo) and button.shouldRender:
    guiState = over
    if leftMb.isDown and button.onClick != nil:
      guiState = interacted
      button.onClick()


method draw*(button: Button, offset = ivec2(0), relativeTo = false) =
  if button.shouldRender:
    glEnable(GlDepthTest)
    with uiShader:
      button.setupUniforms(uiShader)
      uiShader.setUniform("modelMatrix", button.calculateAnchorMatrix(offset = offset, relativeTo = relativeTo))
      uiShader.setUniform("color"):
        if button.isOver(offset = offset):
          vec4(button.color.xyz * 0.5, button.color.w)
        else:
          button.color


      uiShader.setUniform("backgroundColor"):
        if button.isOver(offset = offset, relativeTo = relativeTo):
          vec4(button.backgroundColor.xyz * 0.5, 1)
        else:
          vec4(button.backgroundColor.xyz, 1)
      withBlend:
        render(uiQuad)
      button.label.draw(offset, relativeTo)
  button.label.pos = button.pos
  button.label.size = button.size
  button.label.anchor = button.anchor
  button.label.zDepth = button.zDepth - 1
