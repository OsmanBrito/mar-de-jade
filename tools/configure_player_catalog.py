"""Apply the initial playable Portugal balance; retain art provenance."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / 'data/chapter_01/items.json'
data = json.loads(path.read_text(encoding='utf-8'))
data['status'] = 'playable_initial_balance'
data['rules']['prices_and_stats_defined'] = True
data['rules']['currency'] = 'reais'
data['rules']['service_payment'] = 40
data['rules']['sell_price_fraction'] = 0.5
balance = {
    'PT-W01': (28, {'attack': 2}, 'weapon', 'ES', 'Lâmina de treino bem equilibrada. Potência +2.'),
    'PT-W02': (26, {'attack': 2}, 'weapon', 'LA', 'Haste simples para guardar a distância. Potência +2.'),
    'PT-W03': (30, {'attack': 3}, 'weapon', 'MC', 'Cabeça pesada para o manejo de machado. Potência +3.'),
    'PT-W04': (38, {'attack': 2}, 'weapon', 'FO', 'Arma de treino do manejo de fogo. Potência +2.'),
    'PT-W05': (8, {'posture': 4}, 'weapon', 'PU', 'Apoio opcional às mãos. Postura +4; lutar desarmado não exige faixas.'),
    'PT-V01': (24, {'hp': 12, 'defense': 2}, 'outfit', None, 'Gibão reforçado para praticar no pátio. Vida +12, proteção +2.'),
    'PT-V02': (18, {'hp': 8, 'posture': 6}, 'outfit', None, 'Capa de tecido resistente. Vida +8, postura +6.'),
    'PT-V03': (16, {'posture': 8, 'speed': 1}, 'feet', None, 'Sola firme para a viagem. Postura +8, velocidade +1.'),
    'PT-A01': (20, {'qi': 2, 'posture': 6}, 'accessory', None, 'Mantém o material junto ao corpo. Alento +2, postura +6.'),
    'PT-A02': (6, {'posture': 4}, 'accessory', None, 'Corda entrançada num apoio simples. Postura +4.'),
    'PT-C01': (6, {}, None, None, 'Trata escoriações fora de combate: recupera 25 de vida. Não substitui o tratamento de Tomé.'),
    'PT-C02': (5, {}, None, None, 'Uma pausa para comer: recupera 15 de vida e 3 de alento fora de combate.'),
    'PT-C03': (3, {}, None, None, 'Água de viagem: recupera 5 de alento fora de combate.'),
}
for row in data['items']:
    if row['id'] not in balance:
        row['stats'] = {}
        continue
    price, stats, slot, style, description = balance[row['id']]
    row.update(price=price, stats=stats, slot=slot, description=description,
               stock=6 if row['category'] == 'supply' else 2,
               design_status='playable_initial_balance')
    if style:
        row['style'] = style
    if row['id'] in ('PT-C01', 'PT-C02', 'PT-C03'):
        row['recovery'] = {'PT-C01': {'hp': 25}, 'PT-C02': {'hp': 15, 'qi': 3}, 'PT-C03': {'qi': 5}}[row['id']]
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
