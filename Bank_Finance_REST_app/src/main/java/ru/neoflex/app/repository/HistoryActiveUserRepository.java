package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.HistoryActiveUser;

public interface HistoryActiveUserRepository extends JpaRepository<HistoryActiveUser, Long> {
}
