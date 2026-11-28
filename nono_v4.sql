-- nono 4차 (2026-11-28, 커넥터로 실행)
-- 해지 알림(체크한 정기결제만, 결제 이틀 전 팝업 — 답한 회차는 서버에 기억), 결제 대행(페이) 칸
alter table nono_recurring add column if not exists cancel_alert boolean not null default false;
alter table nono_recurring add column if not exists alerted_on date;   -- 알림을 본 결제 예정일
alter table nono_recurring add column if not exists via text;          -- 네이버페이·카카오페이·토스페이
alter table nono_tx add column if not exists via text;
-- '말일' 버튼을 없애서 말일(0)은 31로 (31일이 없는 달은 그달 마지막 날로 찍혀서 결과는 같음)
update nono_recurring set day=31 where day=0;
-- '이번만 건너뛰기' 기능을 없애므로, 건너뛴 상태(미래 날짜)는 오늘로 되돌림 → 11.30 회차도 정상으로 찍힘
update nono_recurring set last_on='2026-11-28' where last_on>'2026-11-28';
