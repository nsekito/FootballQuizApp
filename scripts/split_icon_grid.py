from PIL import Image
import os

# 16アイコングリッドを切り出し
img_path = 'assets/images/01_Icons/icon_set_16_grid.png'
output_dir = 'assets/images/01_Icons/split'

# 出力ディレクトリを作成
os.makedirs(output_dir, exist_ok=True)

img = Image.open(img_path)
width, height = img.size
icon_size = width // 4

icon_names = [
    'whistle', 'trophy', 'jersey', 'calendar',
    'clock', 'chart', 'check', 'cross',
    'star', 'shield', 'flag', 'play',
    'bulb', 'calendar_ball', 'arrow_left', 'close'
]

for i in range(16):
    row = i // 4
    col = i % 4
    left = col * icon_size
    top = row * icon_size
    right = left + icon_size
    bottom = top + icon_size
    
    icon = img.crop((left, top, right, bottom))
    output_path = os.path.join(output_dir, f'icon_{icon_names[i]}.png')
    icon.save(output_path)
    print(f'Saved: {output_path}')

print('Icon splitting completed!')
