package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.Role;

public interface RoleRepository extends JpaRepository<Role, Long> {
}