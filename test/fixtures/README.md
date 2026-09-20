# Fixtures

`categories_income_response.json` / `categories_expense_response.json` are
raw, unmodified `GET /api/v1/categories?type=income|expense` responses
captured against the `dev` backend (see `env/dev.json` for the URL/key).

These back `test/shared/widgets/category_icon_test.dart`'s icon-resolver
coverage test — the test reads every `icon_key` straight out of these files
rather than a hand-typed Dart list. Three rounds of category-icon-fallback
bugs (post-launch UI polish tickets 01, 07, and 08) shipped specifically
because both the resolver *and* its coverage test hardcoded a snapshot of
the key list in source, which silently went stale the next time a category
was added to the seed data.

Ticket 09 root-caused the resolver side of that: `resolveCategoryIcon`
(`lib/shared/widgets/category_icon.dart`) now resolves against
`kRemixIconCodepoints`, a *complete* name -> codepoint map mechanically
generated from `package:remix_icons_flutter`'s own source (see
`tool/generate_remix_icon_codepoints.dart`), not a hand-picked subset — so a
brand-new backend category needs no frontend change as long as its
`icon_key` is a real Remix Icon name. These fixtures (and the test reading
them) still matter regardless: they're what proves *today's* categories all
resolve correctly, and they're the only way this test can go stale is the
fixture itself going stale — one obvious file to refresh, not Dart literals
scattered through test code.

**When to refresh:** whenever a new category is added to the backend seed
data (or the resolver test starts complaining about an unrecognized
`icon_key`). Re-fetch and overwrite both files:

```
curl -s -H "X-API-Key: $(python3 -c "import json;print(json.load(open('env/dev.json'))['API_KEY'])")" \
  "$(python3 -c "import json;print(json.load(open('env/dev.json'))['BASE_URL'])")/api/v1/categories?type=income" \
  | python3 -m json.tool > test/fixtures/categories_income_response.json

curl -s -H "X-API-Key: $(python3 -c "import json;print(json.load(open('env/dev.json'))['API_KEY'])")" \
  "$(python3 -c "import json;print(json.load(open('env/dev.json'))['BASE_URL'])")/api/v1/categories?type=expense" \
  | python3 -m json.tool > test/fixtures/categories_expense_response.json
```

Never hand-edit these files or invent entries — they're a stand-in for
whatever the live backend actually returns, and are only useful as long as
that's true.
