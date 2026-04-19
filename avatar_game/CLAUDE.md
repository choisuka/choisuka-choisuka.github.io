# Avatar Game - CLAUDE.md

## 프로젝트 목적 및 방향성

### 목적
`avatar_shop`에서 구매/장착한 아이템이 실제 게임 캐릭터에 반영되는 **아바타 기반 Python 게임**.
쇼핑몰과 게임이 하나의 생태계를 이루며, 유저가 쇼핑몰에서 꾸민 캐릭터로 게임을 플레이한다.

### 방향성
- 쇼핑몰(`avatar_shop`) API를 호출해 로그인한 유저의 장착 아이템을 가져와 캐릭터에 렌더링
- 게임 내에서 코인을 획득하면 쇼핑몰 API를 통해 유저 코인 잔액에 반영
- 게임 종류는 미정 (추후 결정)
- Python 기반으로 개발

### 연동 구조
```
[ avatar_game (Python 게임) ]
        ↕  JWT + REST API
[ avatar_shop (Flask 쇼핑몰) ]
        ↕
   [ shop.db (SQLite) ]
```

---

## 개발 환경

| 항목 | 내용 |
|------|------|
| OS | Windows 10 Pro (10.0.19045) |
| Python | 3.9.13 |
| 위치 | `C:\Users\USER\avatar_game` |
| 게임 라이브러리 | 미정 |

---

## 환경 세팅 방법 (예정)

```cmd
cd C:\Users\USER\avatar_game
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt  # 추후 작성
python main.py
```

---

## 연동 쇼핑몰 정보

| 항목 | 내용 |
|------|------|
| 위치 | `C:\Users\USER\avatar_shop` |
| API 주소 | `http://127.0.0.1:5000` |
| 인증 방식 | JWT (Authorization: Bearer 헤더) |

### 게임에서 사용할 핵심 API

```python
BASE = "http://127.0.0.1:5000"

# 로그인 → JWT 토큰 획득
POST /auth/login
Body: { "email": "...", "password": "..." }
Response: { "access_token": "...", "username": "..." }

# 장착 아이템 조회 → 캐릭터 렌더링에 사용
GET /equip/
Header: Authorization: Bearer <token>
Response: [
  {
    "item": {
      "id": 1,
      "name": "빨간 후드티",
      "category": "top",
      "image_url": "https://...",
      "layer_order": 2   ← 렌더링 순서 (낮을수록 하단)
    }
  }
]

# 코인 잔액 + 장착 아이템 한 번에 조회
GET /auth/me
Header: Authorization: Bearer <token>
Response: { "coins": 1000, "username": "...", "equipped_items": [...] }

# 게임에서 코인 획득 시 쇼핑몰에 반영
POST /auth/coins/charge
Header: Authorization: Bearer <token>
Body: { "amount": 100 }
```

### API 호출 예시 (Python, 추가 라이브러리 없이)

```python
import urllib.request
import json

BASE = "http://127.0.0.1:5000"

def api(method, path, body=None, token=None):
    url = BASE + path
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read())

# 로그인
result = api("POST", "/auth/login", {"email": "test@test.com", "password": "pass1234"})
token = result["access_token"]

# 장착 아이템 조회 (layer_order 순 정렬해서 렌더링)
equips = api("GET", "/equip/", token=token)
equips.sort(key=lambda e: e["item"]["layer_order"])
for e in equips:
    print(e["item"]["name"], e["item"]["image_url"])
```

---

## 아이템 카테고리 및 layer_order 규칙

| 카테고리 | layer_order 기본값 | 설명 |
|----------|-------------------|------|
| shoes | 0 | 가장 아래 레이어 |
| bottom | 1 | 하의 |
| top | 2 | 상의 |
| accessory | 3 | 가장 위 레이어 |

- `layer_order`가 낮을수록 먼저 그려지고(하단), 높을수록 위에 그려짐
- 아이템 등록 시 관리자가 직접 지정 가능

---

## 테스트 계정 (avatar_shop 기준)

| username | email | password | coins | 관리자 |
|----------|-------|----------|-------|--------|
| testuser | test@test.com | pass1234 | 1500 | X |
| tester | tester@test.com | pass1234 | 1100 | O |

게임 테스트 전 `avatar_shop` 서버를 먼저 실행해야 함:
```cmd
cd C:\Users\USER\avatar_shop
venv\Scripts\activate
python app.py
```

---

## 주요 대화 내용 / 결정 사항

- 게임 종류는 아직 미정, 방향성 결정 후 개발 시작
- Python으로 개발하며 pygame 등 게임 라이브러리 도입 예정
- 쇼핑몰과의 연동은 REST API + JWT 방식으로 확정
- 게임에서 코인을 획득하면 `POST /auth/coins/charge`로 쇼핑몰에 반영하는 구조
- 아바타 렌더링은 `layer_order` 기준으로 이미지를 순서대로 겹쳐 그리는 방식

---

## 디렉토리 구조 (예정)

```
avatar_game/
├── CLAUDE.md
├── requirements.txt   (추후 작성)
├── main.py            (게임 진입점, 추후 생성)
└── (개발 예정)
```

---

## 미구현 / 추후 개발 예정

- [ ] 게임 종류 결정
- [ ] 게임 라이브러리 선택 및 환경 세팅
- [ ] 쇼핑몰 로그인 연동 (게임 실행 시 로그인)
- [ ] 장착 아이템 기반 캐릭터 렌더링
- [ ] 게임 내 코인 획득 → 쇼핑몰 반영
