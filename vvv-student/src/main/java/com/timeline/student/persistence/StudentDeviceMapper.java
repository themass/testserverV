package com.timeline.student.persistence;

import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import java.util.List;

/**
 * student_* tables only. Times are UTC_TIMESTAMP() so a server timezone change cannot reorder history.
 * No query here selects IP addresses, names or any free text because none of those columns exist.
 */
public interface StudentDeviceMapper {
    record DeviceRow(String id, String audience, String consentVersion, String createdAt) {}
    record SessionRow(String workId, String lastStep, String visited, String audience, String enteredAt,
                      String updatedAt) {}
    record BoardRow(String pointId, int coveredDevices, int missingDevices) {}

    @Insert("INSERT INTO student_device (id, key_sha256, audience, consent_version, created_at, last_seen_at) "
        + "VALUES (#{id}, #{keySha256}, #{audience}, #{consentVersion}, UTC_TIMESTAMP(), UTC_TIMESTAMP())")
    int insertDevice(@Param("id") String id, @Param("keySha256") String keySha256,
                     @Param("audience") String audience, @Param("consentVersion") String consentVersion);

    @Select("SELECT d.id, d.audience, d.consent_version, DATE_FORMAT(d.created_at,'%Y-%m-%dT%H:%i:%sZ') "
        + "FROM student_device d WHERE d.key_sha256=#{keySha256}")
    DeviceRow deviceByKey(@Param("keySha256") String keySha256);

    /** At most once an hour per device: this is "last active", not a tracking trail. */
    @Update("UPDATE student_device SET last_seen_at=UTC_TIMESTAMP() WHERE id=#{id} "
        + "AND last_seen_at < UTC_TIMESTAMP() - INTERVAL 1 HOUR")
    int touchDevice(@Param("id") String id);

    @Update("UPDATE student_device SET audience=#{audience} WHERE id=#{id}")
    int setAudience(@Param("id") String id, @Param("audience") String audience);

    @Insert("INSERT INTO student_session (device_id, work_id, last_step, visited, audience, entered_at, updated_at) "
        + "VALUES (#{deviceId}, #{workId}, #{lastStep}, #{visited}, #{audience}, UTC_TIMESTAMP(), UTC_TIMESTAMP()) "
        + "ON DUPLICATE KEY UPDATE last_step=VALUES(last_step), visited=VALUES(visited), "
        + "audience=VALUES(audience), updated_at=UTC_TIMESTAMP()")
    int upsertSession(@Param("deviceId") String deviceId, @Param("workId") String workId,
                      @Param("lastStep") String lastStep, @Param("visited") String visited,
                      @Param("audience") String audience);

    @Select("SELECT s.work_id, s.last_step, s.visited, s.audience, "
        + "DATE_FORMAT(s.entered_at,'%Y-%m-%dT%H:%i:%sZ'), DATE_FORMAT(s.updated_at,'%Y-%m-%dT%H:%i:%sZ') "
        + "FROM student_session s WHERE s.device_id=#{deviceId} ORDER BY s.updated_at DESC LIMIT 100")
    List<SessionRow> sessions(@Param("deviceId") String deviceId);

    @Insert("INSERT INTO student_event (device_id, work_id, step, kind, ref, ms, client_at, created_at) "
        + "VALUES (#{deviceId}, #{workId}, #{step}, #{kind}, #{ref}, #{ms}, #{clientAt}, UTC_TIMESTAMP())")
    int insertEvent(@Param("deviceId") String deviceId, @Param("workId") String workId,
                    @Param("step") String step, @Param("kind") String kind, @Param("ref") String ref,
                    @Param("ms") Integer ms, @Param("clientAt") String clientAt);

    @Insert("INSERT INTO student_gap (device_id, work_id, script_hash, point_id, state, created_at) "
        + "VALUES (#{deviceId}, #{workId}, #{scriptHash}, #{pointId}, #{state}, UTC_TIMESTAMP())")
    int insertGap(@Param("deviceId") String deviceId, @Param("workId") String workId,
                  @Param("scriptHash") String scriptHash, @Param("pointId") String pointId,
                  @Param("state") String state);

    @Select("SELECT COUNT(DISTINCT g.device_id) FROM student_gap g WHERE g.work_id=#{workId} AND g.script_hash=#{scriptHash}")
    int boardDevices(@Param("workId") String workId, @Param("scriptHash") String scriptHash);

    @Select("SELECT g.point_id, COUNT(DISTINCT CASE WHEN g.state='COVERED' THEN g.device_id END), "
        + "COUNT(DISTINCT CASE WHEN g.state='MISSING' THEN g.device_id END) FROM student_gap g "
        + "WHERE g.work_id=#{workId} AND g.script_hash=#{scriptHash} GROUP BY g.point_id ORDER BY g.point_id LIMIT 100")
    List<BoardRow> board(@Param("workId") String workId, @Param("scriptHash") String scriptHash);

    @Delete("DELETE FROM student_event WHERE device_id=#{deviceId}")
    int deleteEvents(@Param("deviceId") String deviceId);

    @Delete("DELETE FROM student_gap WHERE device_id=#{deviceId}")
    int deleteGaps(@Param("deviceId") String deviceId);

    @Delete("DELETE FROM student_session WHERE device_id=#{deviceId}")
    int deleteSessions(@Param("deviceId") String deviceId);

    @Delete("DELETE FROM student_device WHERE id=#{deviceId}")
    int deleteDevice(@Param("deviceId") String deviceId);
}
