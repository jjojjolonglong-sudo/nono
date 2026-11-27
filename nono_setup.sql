-- nono 가계부 테이블 (2026-11-27, 커넥터로 실행)
-- 계좌·카드·현금·대출 등
create table if not exists nono_account(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null default '예금계좌',      -- 예금계좌·현금·체크카드·신용카드·주식계좌·대출·기타
  name text not null,
  link_id uuid references nono_account(id) on delete set null, -- 체크카드·신용카드가 빠져나가는 통장
  pay_day int,                                -- 신용카드 결제일
  base bigint not null default 0,             -- 시작 잔액(대출은 원금, 음수 아님)
  value bigint, value_on date,                -- 주식 평가액과 그 날짜
  sort int not null default 0,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
-- 분류 (지출·수입 따로)
create table if not exists nono_category(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null default '지출',          -- 지출·수입
  name text not null,
  sort int not null default 0,
  created_at timestamptz not null default now(),
  unique(user_id,kind,name)
);
-- 정기결제·공과금
create table if not exists nono_recurring(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  vendor text,
  amount bigint,                              -- 비우면 금액이 매번 다름
  category_id uuid references nono_category(id) on delete set null,
  account_id uuid references nono_account(id) on delete set null,
  every text not null default '월',           -- 월·년
  day int not null default 1,                 -- 1~31, 0 = 말일
  month int,                                  -- 매년일 때 달
  active boolean not null default true,
  start_on date not null default (now() at time zone 'Asia/Seoul')::date,
  last_on date,                               -- 마지막으로 찍은 날
  sort int not null default 0,
  created_at timestamptz not null default now()
);
-- 거래
create table if not exists nono_tx(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  day date not null,
  type text not null check (type in ('지출','수입','이체','돌려받음')),
  amount bigint,                              -- 비어 있으면 금액 채우기(정기결제 변동분)
  vendor text,
  category_id uuid references nono_category(id) on delete set null,
  account_id uuid references nono_account(id) on delete set null,     -- 쓴 곳·들어온 곳·보낸 곳
  to_account_id uuid references nono_account(id) on delete set null,  -- 이체 받은 곳
  inst int,                                   -- 할부 개월(비우면 일시불)
  back bigint not null default 0,             -- 돌려받을 돈(총액)
  parent_id uuid references nono_tx(id) on delete set null,           -- 돌려받음이 연결된 지출
  recurring_id uuid references nono_recurring(id) on delete set null,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists nono_tx_user_day on nono_tx(user_id,day desc);
create index if not exists nono_tx_parent on nono_tx(parent_id) where parent_id is not null;

alter table nono_account enable row level security;
alter table nono_category enable row level security;
alter table nono_recurring enable row level security;
alter table nono_tx enable row level security;
create policy "own rows" on nono_account for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "own rows" on nono_category for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "own rows" on nono_recurring for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "own rows" on nono_tx for all using (user_id=auth.uid()) with check (user_id=auth.uid());
