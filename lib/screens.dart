import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'converters.dart';
import 'strings.dart';

class Settings extends ChangeNotifier {
  int digits = 6;
  bool persian = true;
  void update({int? d, bool? p}) {
    digits = d ?? digits;
    persian = p ?? persian;
    notifyListeners();
  }
}

final settings = Settings();

class Bouncy extends StatefulWidget {
  const Bouncy({super.key, required this.onTap, required this.builder});
  final VoidCallback onTap;
  final Widget Function(BuildContext context, bool pressed) builder;
  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => down = true),
    onTapCancel: () => setState(() => down = false),
    onTapUp: (_) {
      setState(() => down = false);
      widget.onTap();
    },
    child: AnimatedScale(
      scale: down ? .94 : 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      child: widget.builder(context, down),
    ),
  );
}

BorderRadius _shape(int i) {
  const big = Radius.circular(40), small = Radius.circular(14);
  return switch (i % 4) {
    0 => const BorderRadius.only(
      topLeft: big,
      topRight: small,
      bottomLeft: small,
      bottomRight: big,
    ),
    1 => const BorderRadius.only(
      topLeft: small,
      topRight: big,
      bottomLeft: big,
      bottomRight: small,
    ),
    2 => BorderRadius.circular(40),
    _ => const BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: small,
      bottomRight: small,
    ),
  };
}

void _open(BuildContext context, Category c, {String? from, String? to}) =>
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) =>
            ConverterScreen(cat: c, fromKey: from, toKey: to),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String q = '';

  static const _popular = [
    ('mass', 'kg', 'lb'),
    ('length', 'cm', 'in'),
    ('length', 'mm', 'in'),
    ('mass', 'g', 'oz'),
    ('temperature', '°C', '°F'),
    ('length', 'ft', 'm'),
  ];

  bool _match(Category c) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return c.fa.contains(s) ||
        c.key.contains(s) ||
        c.units.any((u) => u.fa.contains(s) || u.sym.toLowerCase().contains(s));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = categories.where(_match).toList();

    final roles = [
      (cs.primaryContainer, cs.onPrimaryContainer),
      (cs.tertiaryContainer, cs.onTertiaryContainer),
      (cs.secondaryContainer, cs.onSecondaryContainer),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              S.appTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SearchBar(
                hintText: S.search,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.search),
                ),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  cs.surfaceContainerHigh,
                ),
                onChanged: (v) => setState(() => q = v),
              ),
            ),
          ),
          if (q.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(S.popular, style: tt.titleMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _popular.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (ck, f, t) = _popular[i];
                    final c = catByKey(ck);
                    return ActionChip(
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                      backgroundColor: cs.surfaceContainerHighest,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      label: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          '${c.unit(f).fa} ${S.toWord} ${c.unit(t).fa}',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(fontSize: 13, height: 1.2),
                        ),
                      ),
                      onPressed: () => _open(context, c, from: f, to: t),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(S.categories, style: tt.titleMedium),
              ),
            ),
          ],
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(S.nothingFound)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  final (bg, fg) = roles[i % roles.length];
                  return Bouncy(
                    onTap: () => _open(context, c),
                    builder: (_, down) => AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: down
                            ? BorderRadius.circular(56)
                            : _shape(i),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Hero(
                            tag: 'ic-${c.key}',
                            child: Icon(c.icon, size: 40, color: fg),
                          ),
                          Text(
                            c.fa,
                            maxLines: 2,
                            style: tt.titleMedium?.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── converter ─────────────────────────

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({
    super.key,
    required this.cat,
    this.fromKey,
    this.toKey,
  });
  final Category cat;
  final String? fromKey, toKey;
  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  Unit? from, to;
  final ctrl = TextEditingController(text: '1');
  double turns = 0;

  Category get cat => widget.cat;
  bool get isCurrency => cat.key == 'currency';

  @override
  void initState() {
    super.initState();
    if (cat.units.isNotEmpty) {
      _setUnits();
    } else if (isCurrency) {
      _loadCurrency();
    }
  }

  void _setUnits() {
    from = cat.unit(widget.fromKey ?? cat.units[0].key);
    to = cat.unit(widget.toKey ?? cat.units[1].key);
  }

  Future<void> _loadCurrency() async {
    setState(() {});
    await Currency.fetch(cat);
    if (!mounted) return;
    setState(() {
      if (cat.units.isNotEmpty) _setUnits();
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _swap() => setState(() {
    final t = from;
    from = to;
    to = t;
    turns += .5;
  });

  Future<void> _pick(bool isFrom) async {
    final cur = (isFrom ? from : to)!;
    final picked = await showModalBottomSheet<Unit>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        maxChildSize: .92,
        builder: (_, sc) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                S.pickUnit,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  for (final u in cat.units)
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      selected: u.key == cur.key,
                      selectedTileColor: Theme.of(ctx)
                          .colorScheme
                          .secondaryContainer,
                      title: Text(u.fa),
                      trailing: Text(u.sym, textDirection: TextDirection.ltr),
                      onTap: () => Navigator.pop(ctx, u),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        from = picked;
      } else {
        to = picked;
      }
    });
  }

  void _settings() => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(S.maxDigits),
              trailing: Text(
                fmt(
                  settings.digits.toDouble(),
                  digits: 0,
                  persian: settings.persian,
                ),
              ),
            ),
            Slider(
              value: settings.digits.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => settings.update(d: v.round()),
            ),
            SwitchListTile(
              title: const Text(S.persianDigits),
              value: settings.persian,
              onChanged: (v) => settings.update(p: v),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (from == null || to == null) {
      return Scaffold(
        appBar: AppBar(title: Text(cat.fa)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: cat.loading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(S.ratesLoading),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 40, color: cs.error),
                      const SizedBox(height: 12),
                      Text(
                        cat.error ?? S.ratesLoading,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadCurrency,
                        icon: const Icon(Icons.refresh),
                        label: const Text(S.retry),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final f = from!, t = to!;
        String show(double x) =>
            fmt(x, digits: settings.digits, persian: settings.persian);
        final v = parseNum(ctrl.text);
        final result = v == null ? null : convert(v, f, t);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Hero(tag: 'ic-${cat.key}', child: Icon(cat.icon)),
                const SizedBox(width: 12),
                Text(cat.fa),
              ],
            ),
            actions: [
              if (isCurrency)
                IconButton(
                  onPressed: _loadCurrency,
                  icon: const Icon(Icons.refresh),
                ),
              IconButton(onPressed: _settings, icon: const Icon(Icons.tune)),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final converterCard = Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      // ── input
                      _Panel(
                        color: cs.surfaceContainerHigh,
                        radius: const BorderRadius.only(
                          topLeft: Radius.circular(44),
                          topRight: Radius.circular(44),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.from,
                              style: tt.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    onChanged: (_) => setState(() {}),
                                    textDirection: TextDirection.ltr,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9۰-۹٠-٩.,٫٬eE+\-]'),
                                      ),
                                    ],
                                    style: tt.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                                _UnitButton(unit: f, onTap: () => _pick(true)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ── result
                      _Panel(
                        color: cs.primaryContainer,
                        radius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(44),
                          bottomRight: Radius.circular(44),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.to,
                              style: tt.labelLarge?.copyWith(
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: result == null
                                        ? null
                                        : () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: fmt(
                                                  result,
                                                  digits: settings.digits,
                                                  persian: false,
                                                ),
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                content: Text(S.copied),
                                              ),
                                            );
                                          },
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        result == null ? '—' : show(result),
                                        textDirection: TextDirection.ltr,
                                        style: tt.displaySmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: cs.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _UnitButton(unit: t, onTap: () => _pick(false)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${show(1)} ${f.fa} = ${show(convert(1, f, t))} ${t.fa}',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onPrimaryContainer.withValues(
                                  alpha: .8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // ── swap
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton.filled(
                      iconSize: 28,
                      onPressed: _swap,
                      icon: AnimatedRotation(
                        turns: turns,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        child: const Icon(Icons.swap_vert),
                      ),
                    ),
                  ),
                ],
              );

              final unitsList = Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: cs.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    for (final u in cat.units)
                      if (u.key != f.key)
                        ListTile(
                          selected: u.key == t.key,
                          selectedTileColor: cs.tertiaryContainer,
                          title: Text(u.fa),
                          subtitle: Text(
                            u.sym,
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: Text(
                            v == null ? '—' : show(convert(v, f, u)),
                            textDirection: TextDirection.ltr,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => setState(() => to = u),
                        ),
                  ],
                ),
              );

              final wide = constraints.maxWidth >= 600;

              if (wide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 420, child: converterCard),
                          const SizedBox(width: 28),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    8,
                                    8,
                                  ),
                                  child: Text(
                                    S.allUnits,
                                    style: tt.titleMedium,
                                  ),
                                ),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: unitsList,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  converterCard,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    child: Text(S.allUnits, style: tt.titleMedium),
                  ),
                  unitsList,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.color,
    required this.radius,
    required this.child,
  });
  final Color color;
  final BorderRadius radius;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 150),
    padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
    decoration: BoxDecoration(color: color, borderRadius: radius),
    child: child,
  );
}

class _UnitButton extends StatelessWidget {
  const _UnitButton({required this.unit, required this.onTap});
  final Unit unit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 150),
    child: FilledButton.tonalIcon(
      style: FilledButton.styleFrom(shape: const StadiumBorder()),
      onPressed: onTap,
      icon: const Icon(Icons.expand_more),
      label: Text(unit.fa, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
