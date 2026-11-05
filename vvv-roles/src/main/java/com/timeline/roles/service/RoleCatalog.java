package com.timeline.roles.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Read-only role catalog loaded once from classpath JSON (see tools/roles/build_catalog.py).
 * Chinese display text lives in an optional overlay file and falls back to the English source.
 */
public class RoleCatalog {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Division(String id, String label, String icon, String color) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Role(String id, String division, String name, String description, String emoji,
                       String color, String vibe, boolean featured, String prompt) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Overlay(String name, String description, String vibe) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Source(List<Division> divisions, List<Role> roles) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record DivisionLabels(Map<String, String> divisions, Map<String, Overlay> roles) {}

    private final List<Division> divisions;
    private final List<Role> roles;
    private final Map<String, Role> byId;
    private final Map<String, Overlay> overlays;
    private final Map<String, String> divisionLabelsZh;

    public RoleCatalog(ObjectMapper mapper, String catalogPath, String overlayPath) {
        Source source = read(mapper, catalogPath, Source.class, true);
        DivisionLabels zh = read(mapper, overlayPath, DivisionLabels.class, false);
        this.divisions = List.copyOf(source.divisions());
        this.roles = List.copyOf(source.roles());
        Map<String, Role> index = new LinkedHashMap<>();
        for (Role role : roles) {
            if (index.put(role.id(), role) != null) {
                throw new IllegalStateException("duplicate role id " + role.id());
            }
        }
        this.byId = Collections.unmodifiableMap(index);
        this.overlays = zh == null || zh.roles() == null ? Map.of() : zh.roles();
        this.divisionLabelsZh = zh == null || zh.divisions() == null ? Map.of() : zh.divisions();
    }

    private static <T> T read(ObjectMapper mapper, String path, Class<T> type, boolean required) {
        try (InputStream in = RoleCatalog.class.getResourceAsStream(path)) {
            if (in == null) {
                if (required) throw new IllegalStateException("missing resource " + path);
                return null;
            }
            return mapper.readValue(in, type);
        } catch (IOException e) {
            throw new UncheckedIOException("cannot read " + path, e);
        }
    }

    public List<Division> divisions() { return divisions; }

    public String divisionLabel(Division d, boolean zh) {
        return zh ? divisionLabelsZh.getOrDefault(d.id(), d.label()) : d.label();
    }

    public Role find(String id) { return id == null ? null : byId.get(id); }

    /** The system prompt for a role, or null when the id is unknown. */
    public String promptFor(String id) {
        Role role = find(id);
        return role == null ? null : role.prompt();
    }

    public String displayName(Role role, boolean zh) {
        Overlay o = zh ? overlays.get(role.id()) : null;
        return o != null && notBlank(o.name()) ? o.name() : role.name();
    }

    public String displayDescription(Role role, boolean zh) {
        Overlay o = zh ? overlays.get(role.id()) : null;
        return o != null && notBlank(o.description()) ? o.description() : role.description();
    }

    public String displayVibe(Role role, boolean zh) {
        Overlay o = zh ? overlays.get(role.id()) : null;
        return o != null && notBlank(o.vibe()) ? o.vibe() : role.vibe();
    }

    /** Filter by division (exact), featured flag and a case-insensitive text query. */
    public List<Role> search(String division, String query, boolean featuredOnly, boolean zh) {
        String q = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);
        List<Role> out = new ArrayList<>();
        for (Role r : roles) {
            if (division != null && !division.isEmpty() && !division.equals(r.division())) continue;
            if (featuredOnly && !r.featured()) continue;
            if (!q.isEmpty() && !matches(r, q, zh)) continue;
            out.add(r);
        }
        return out;
    }

    private boolean matches(Role r, String q, boolean zh) {
        return contains(r.id(), q) || contains(r.name(), q) || contains(r.description(), q)
                || contains(displayName(r, zh), q) || contains(displayDescription(r, zh), q);
    }

    private static boolean contains(String s, String q) {
        return s != null && s.toLowerCase(Locale.ROOT).contains(q);
    }

    private static boolean notBlank(String s) { return s != null && !s.isBlank(); }
}
