"""data/weekly_recap の最新週の JSON を questions.db に取り込むスクリプト

Weekly Recap は週ごとに同じ ID (w_00001 等) を使うため、最新週のみを DB に取り込む。
ローカル DB を最新の Weekly Recap で更新する際に使用。
GitHub Actions では generate-weekly-recap.yml が自動で実行する。
"""
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
WEEKLY_RECAP_DIR = PROJECT_ROOT / "data" / "weekly_recap"


def get_latest_week_files():
    """最新週の JSON ファイルのみを返す（YYYY-MM-DD 形式の日付で判定）"""
    all_files = list(WEEKLY_RECAP_DIR.glob("*.json"))
    if not all_files:
        return []

    # ファイル名から日付を抽出（例: 2026-03-02_j1.json -> 2026-03-02）
    def extract_date(p: Path) -> str | None:
        name = p.stem  # 2026-03-02_j1
        if "_" in name:
            return name.split("_")[0]  # 2026-03-02
        return None

    dates = {extract_date(p) for p in all_files if extract_date(p)}
    if not dates:
        return sorted(all_files)

    latest_date = max(dates)
    return sorted(p for p in all_files if p.stem.startswith(latest_date + "_"))


def main():
    if not WEEKLY_RECAP_DIR.exists():
        print(f"エラー: {WEEKLY_RECAP_DIR} が見つかりません")
        sys.exit(1)

    json_files = get_latest_week_files()
    if not json_files:
        print(f"警告: {WEEKLY_RECAP_DIR} に JSON ファイルがありません")
        sys.exit(0)

    print(f"Weekly Recap JSON を questions.db に取り込みます（{len(json_files)} ファイル）")
    print("=" * 60)

    failed_files = []
    for json_path in json_files:
        print(f"\n処理中: {json_path.name}")
        result = subprocess.run(
            [
                sys.executable,
                str(PROJECT_ROOT / "scripts" / "json_to_db.py"),
                str(json_path),
                "--no-cleanup",
            ],
            cwd=str(PROJECT_ROOT),
        )
        if result.returncode != 0:
            print(f"  スキップ: {json_path.name}（旧形式の可能性）")
            failed_files.append(json_path.name)

    print("\n" + "=" * 60)
    print("完了: questions.db を更新しました")
    if failed_files:
        print(f"\nスキップしたファイル（旧形式）: {', '.join(failed_files)}")


if __name__ == "__main__":
    main()
