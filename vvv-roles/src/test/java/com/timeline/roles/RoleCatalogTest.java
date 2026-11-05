package com.timeline.roles;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.roles.service.RoleCatalog;
import com.timeline.roles.service.RoleCatalog.Role;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class RoleCatalogTest {
    static RoleCatalog catalog;

    @BeforeAll
    static void load() {
        catalog = new RoleCatalog(new ObjectMapper(), "/roles/catalog.json", "/roles/catalog-zh.json");
    }

    @Test
    void everyRoleHasAKnownDivisionAndAUsablePrompt() {
        Set<String> divisions = new HashSet<>();
        catalog.divisions().forEach(d -> divisions.add(d.id()));
        List<Role> all = catalog.search(null, null, false, false);
        assertTrue(all.size() > 200, "expected the full catalog, got " + all.size());
        for (Role r : all) {
            assertTrue(divisions.contains(r.division()), r.id() + " has unknown division " + r.division());
            assertFalse(r.name().isBlank(), r.id());
            assertTrue(r.prompt().length() >= 300, r.id() + " prompt too short");
            assertTrue(r.prompt().length() <= 5000, r.id() + " prompt too long");
        }
    }

    @Test
    void idsAreUrlSafe() {
        for (Role r : catalog.search(null, null, false, false)) {
            assertTrue(r.id().matches("[a-z0-9-]+"), r.id());
        }
    }

    @Test
    void promptForUnknownIdIsNull() {
        assertNull(catalog.promptFor("no-such-role"));
        assertNull(catalog.promptFor(null));
    }

    @Test
    void promptForKnownIdIsReturned() {
        assertNotNull(catalog.promptFor("engineering-frontend-developer"));
    }

    @Test
    void searchFiltersByDivisionFeaturedAndText() {
        List<Role> eng = catalog.search("engineering", null, false, false);
        assertFalse(eng.isEmpty());
        assertTrue(eng.stream().allMatch(r -> r.division().equals("engineering")));

        List<Role> featured = catalog.search(null, null, true, false);
        assertFalse(featured.isEmpty());
        assertTrue(featured.stream().allMatch(Role::featured));

        List<Role> hits = catalog.search(null, "FRONTEND", false, false);
        assertTrue(hits.stream().anyMatch(r -> r.id().equals("engineering-frontend-developer")));
        assertTrue(catalog.search(null, "zzzz-not-a-role-zzzz", false, false).isEmpty());
    }

    @Test
    void chineseOverlayCoversEveryRoleAndEnglishIsUntouched() {
        for (Role r : catalog.search(null, null, false, false)) {
            String zh = catalog.displayName(r, true);
            assertFalse(zh.isBlank(), r.id());
            assertNotEquals(r.name(), zh, r.id() + " has no Chinese name");
            assertEquals(r.name(), catalog.displayName(r, false));
        }
        for (RoleCatalog.Division d : catalog.divisions()) {
            assertNotEquals(d.label(), catalog.divisionLabel(d, true), d.id());
        }
    }

    @Test
    void searchMatchesChineseNames() {
        List<Role> hits = catalog.search(null, "前端", false, true);
        assertTrue(hits.stream().anyMatch(r -> r.id().equals("engineering-frontend-developer")));
    }
}
