import uielements
import sdl2_nim/sdl

type TextArea* = ref object of UiElement
  fontSize: float32
  active: bool
  text: string
  onTextChange: proc(s: string)

proc new*(
  _: typedesc[TextArea];
  pos, size: IVec2;
  fontSize = 11f;
  backgroundColor = vec4(0.5, 0.5, 0.5, 1);
  color = vec4(1);
  anchor = {left, top};
  onTextChange: proc(s: string) = nil
  ): TextArea =
  let res = result
  result = TextArea(pos: pos, size: size, fontSize: fontSize, color: color, anchor: anchor, backgroundColor: backgroundColor, onTextChange: onTextChange)
  result.texture = genTexture()

proc renderTextBlock(tex: textures.Texture, size: IVec2, message: string, fontSize = 30f, hAlign = CenterAlign, vAlign = MiddleAlign) =
  let
    font = readFont("assets/fonts/MarradaRegular-Yj0O.ttf")
    image = newImage(size.x, size.y)
  font.size = fontSize

  var
    typeSet = font.typeSet(message, size.vec2)
    layout = layoutBounds(typeSet)
  while layout.x.int > size.x or layout.y.int > size.y:
    font.size -= 1
    typeSet = font.typeSet(message, size.vec2)
    layout = layoutBounds(typeSet)

  font.paint = rgb(255, 255, 255)
  image.fillText(typeSet)
  image.copyTo(tex)



method update*(textArea: TextArea, dt: float32, offset = ivec2(0), relativeTo = false) =
  let lmbPressed = leftMb.isPressed
  if textArea.shouldRender() and textArea.isOver():
    if not textArea.active:
      textArea.active = true
      let pos = textArea.calculatePos(offset, relativeTo)
      startTextInput(sdl.Rect(x: pos.x, y: pos.y, w: textArea.size.x, h: textArea.size.y))
    if textArea.text != inputText():
      textArea.texture.renderTextBlock(textArea.size, inputText(), textArea.fontSize, LeftAlign, TopAlign)
      textArea.onTextChange(inputText())
      if textArea.onTextChange != nil:
        textArea.onTextChange(inputText())
  else:
    textArea.active = false
    stopTextInput()



method draw*(textArea: TextArea, offset = ivec2(0), relativeTo = false) =
  if textArea.shouldRender:
    with uishader:
      textArea.setupUniforms(uiShader)
      uiShader.setUniform("modelMatrix", textArea.calculateAnchorMatrix(offset = offset, relativeTo = relativeTo))
      withBlend:
        render(uiQuad)
