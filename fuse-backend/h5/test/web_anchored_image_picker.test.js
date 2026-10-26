const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const picker = fs.readFileSync(path.join(root, 'lib/utils/web_anchored_image_picker.dart'), 'utf8');
const upload = fs.readFileSync(path.join(root, 'lib/utils/upload_oss_util.dart'), 'utf8');
const chat = fs.readFileSync(
  path.join(root, 'lib/pages/message/message_chat/widget/chat_input_widget.dart'),
  'utf8'
);
const mainDart = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');

assert.ok(picker.includes("position = 'fixed'"), 'input must be position:fixed');
assert.ok(picker.includes("accept = 'image/*'"), 'accept image only');
assert.ok(picker.includes('append(input)'), 'append before click');
assert.ok(/append\(input\);[\s\S]*input\.click\(\)/.test(picker), 'append then click');
assert.ok(picker.includes('pointerdown'), 'track pointerdown');
assert.ok(picker.includes('touchstart'), 'track touchstart');
assert.ok(picker.includes('_lastClientX'), 'remember last client X');
assert.ok(!picker.includes('ImagePickerWeb'), 'must not call ImagePickerWeb');

assert.ok(upload.includes('WebAnchoredImagePicker.getImageAsBytes'));
assert.ok(!upload.includes('ImagePickerWeb.getImageAsBytes'));
assert.ok(chat.includes('WebAnchoredImagePicker.getImageAsFile'));
assert.ok(!chat.includes('ImagePickerWeb.getImageAsFile'));
assert.ok(mainDart.includes('WebAnchoredImagePicker.ensurePointerTracking'));

console.log('web_anchored_image_picker tests passed');
