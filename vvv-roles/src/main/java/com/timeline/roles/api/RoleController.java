package com.timeline.roles.api;

import com.timeline.roles.api.RoleModels.DivisionItem;
import com.timeline.roles.api.RoleModels.Page;
import com.timeline.roles.api.RoleModels.Response;
import com.timeline.roles.api.RoleModels.RoleItem;
import com.timeline.roles.service.RoleCatalog;
import com.timeline.roles.service.RoleCatalog.Role;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Public, read-only. The path has no ".json" suffix on purpose: the legacy interceptors
 * (login, version, blacklist, response encryption) only match the legacy "/&#42;&#42;/&#42;.json" paths.
 */
@RestController
@RequestMapping("/api/roles/v1")
public class RoleController {
    static final int MAX_LIMIT = 100;

    private final RoleCatalog catalog;

    public RoleController(RoleCatalog catalog) { this.catalog = catalog; }

    @GetMapping("/divisions")
    public Response<List<DivisionItem>> divisions(@RequestParam(defaultValue = "en") String lang) {
        boolean zh = isChinese(lang);
        List<DivisionItem> items = catalog.divisions().stream()
                .map(d -> new DivisionItem(d.id(), catalog.divisionLabel(d, zh), d.icon(), d.color(),
                        catalog.search(d.id(), null, false, zh).size()))
                .toList();
        return Response.ok(items);
    }

    @GetMapping("/roles")
    public Response<Page<RoleItem>> roles(@RequestParam(required = false) String division,
                                          @RequestParam(required = false) String q,
                                          @RequestParam(defaultValue = "false") boolean featured,
                                          @RequestParam(defaultValue = "en") String lang,
                                          @RequestParam(defaultValue = "50") int limit,
                                          @RequestParam(defaultValue = "0") int offset) {
        if (limit < 1 || limit > MAX_LIMIT || offset < 0) {
            throw new IllegalArgumentException("limit must be 1.." + MAX_LIMIT + " and offset >= 0");
        }
        boolean zh = isChinese(lang);
        List<Role> all = catalog.search(division, q, featured, zh);
        int from = Math.min(offset, all.size());
        int to = Math.min(from + limit, all.size());
        List<RoleItem> items = all.subList(from, to).stream().map(r -> toItem(r, zh)).toList();
        return Response.ok(new Page<>(items, all.size(), limit, offset));
    }

    @GetMapping("/roles/{id}")
    public ResponseEntity<Response<RoleItem>> role(@PathVariable String id,
                                                   @RequestParam(defaultValue = "en") String lang) {
        Role role = catalog.find(id);
        if (role == null) {
            return ResponseEntity.status(404).body(new Response<>(404, null, "Role not found"));
        }
        return ResponseEntity.ok(Response.ok(toItem(role, isChinese(lang))));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Response<Void>> badRequest(IllegalArgumentException e) {
        return ResponseEntity.badRequest().body(new Response<>(400, null, e.getMessage()));
    }

    private RoleItem toItem(Role r, boolean zh) {
        return new RoleItem(r.id(), r.division(), catalog.displayName(r, zh), catalog.displayDescription(r, zh),
                r.emoji(), r.color(), catalog.displayVibe(r, zh), r.featured());
    }

    private static boolean isChinese(String lang) {
        return lang != null && lang.toLowerCase().startsWith("zh");
    }
}
