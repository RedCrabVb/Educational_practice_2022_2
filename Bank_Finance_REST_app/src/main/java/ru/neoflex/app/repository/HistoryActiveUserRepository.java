package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import ru.neoflex.app.domain.HistoryActiveUserSimple;

import java.util.List;

public interface HistoryActiveUserRepository extends JpaRepository<HistoryActiveUserSimple, String>{
    @Query(value = "select uuid, user_id, user_agent, use_session_id, last_active from public.history_active_user_simple", nativeQuery = true)
    List<HistoryActiveUserSimple> getAll();
}
