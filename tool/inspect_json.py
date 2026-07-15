import json
from pathlib import Path

p = Path(r'd:\RODRIGO\termo_app\assets\agua_sobrecalentado.json')
data = json.loads(p.read_text(encoding='utf-8'))
print(type(data).__name__, len(data))
for idx, item in enumerate(data):
    props = item.get('propiedades_por_T', [])
    if not isinstance(props, list):
        print('bad props at', idx, type(props), item)
        break
    for j, prop in enumerate(props):
        if not isinstance(prop, dict):
            print('bad prop item', idx, j, type(prop), prop)
            break
        for key in ['T','v','u','h','s']:
            if key not in prop or prop[key] is None:
                print('missing', key, 'at', idx, j, prop)
                raise SystemExit
else:
    print('all property maps ok')
